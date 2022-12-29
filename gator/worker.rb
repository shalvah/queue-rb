require "securerandom"
require_relative "./logger"
require_relative './models/job'

module Gator
  class Worker
    attr_reader :logger, :worker_id, :queues

    def initialize(queues: [])
      @logger = Gator::Logger.new(level: ::Logger::DEBUG)
      @worker_id = "wrk_" + SecureRandom.hex(8)
      @queues = (queues || []).map do |q|
        q.kind_of?(Array) ? q : [q, 1]
      end

      @all_queues_have_same_priority = @queues.map { _1[1] }.uniq.size == 1
      @max_concurrency = 5
    end

    def run
      logger.info "Worker #{worker_id} ready"
      queues.empty? ?
        logger.info("Watching all queues") :
        logger.info("Watching queues: #{queues.map { |q, p| "#{q} (priority=#{p})" }.join(', ')}")

      @work_queue = Thread::Queue.new
      setup_thread_pool
      setup_signal_handlers

      loop do
        if @should_exit
          @work_queue.close
          child_threads.each(&:join)
          break
        end

        enqueue_any_ripe_jobs

        if (@work_queue.size < @max_concurrency) && (job = next_job)
          @work_queue.push(job)
        end
      end

      puts "Exiting."
    end

    protected

    def next_job
      queue, job_string = check_for_jobs
      return nil if queue == nil

      defaults = {
        'attempts' => 0,
        'state' => 'ready',
        'queue' => queue.sub("queue-", ''),
        'chain_class' => nil,
        'chain_id' => nil,
        'error_details' => nil,
        'last_executed_at' => nil,
        'next_execution_at' => nil,
      }
      job_hash = defaults.merge(JSON(job_string))
      OpenStruct.new(**job_hash)
    end

    def check_for_jobs
      queues_to_check = queues_filter
      logger.info "Checking queues #{queues_to_check}"

      $redis.blpop queues_to_check.map { "queue-#{_1}"}, timeout: 2
    end

    def queues_filter
      return @queues.map(&:first).shuffle if @all_queues_have_same_priority

      if @queues.empty?
        all_queues = $redis.smembers "known-queues"
        return all_queues.empty? ? ['default'] : all_queues.shuffle
      end

      # Adapted from weighted random sampling from Efraimidis and Spirakis, thanks to https://gist.github.com/O-I/3e0654509dd8057b539a
      queues.sort_by { |(_name, priority)| -(rand ** (1.0 / priority)) }.map(&:first)
    end

    def enqueue_any_ripe_jobs
      ripe_scheduled_jobs = $redis.zrange "scheduled", 0, Time.now.to_i, byscore: true
      $redis.multi do |transaction|
        ripe_scheduled_jobs.each do |job_hash|
          Gator::Models::Job.save(JSON(job_hash), connection: transaction)
        end
        transaction.zpopmin "scheduled", ripe_scheduled_jobs.count
      end

      ripe_retry_jobs = $redis.zrange "retry", 0, Time.now.to_i, byscore: true
      $redis.multi do |transaction|
        ripe_retry_jobs.each do |job_hash|
          Gator::Models::Job.save(JSON(job_hash), connection: transaction)
        end
        transaction.zpopmin "retry", ripe_retry_jobs.count
      end
    end

    def setup_signal_handlers
      Signal.trap("SIGINT") do
        if @should_exit
          puts "Force exiting"
          @work_queue.close
          child_threads.each(&:kill)
          exit
        end

        puts "Received SIGINT; waiting for any executing jobs to finish before exiting..."
        @should_exit = true
      end
    end

    def setup_thread_pool
      @max_concurrency.times do
        Thread.new do
          while (job = @work_queue.shift)
            Executor.execute(job)
          end
        end
      end

      logger.debug "Started #{@max_concurrency} executor threads"
    end

    def child_threads
      Thread.list.reject { |t| t == Thread.main }
    end
  end
end
