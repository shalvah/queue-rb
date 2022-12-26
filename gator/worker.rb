require "securerandom"
require_relative "./logger"
require_relative './models/job'

module Gator
  class Worker
    attr_reader :polling_interval, :logger, :worker_id, :queues

    def initialize(queues: [])
      @polling_interval = 4
      @logger = Gator::Logger.new(level: ::Logger::DEBUG)
      @worker_id = "wrk_" + SecureRandom.hex(8)
      @queues = (queues || []).map do |q|
        q.kind_of?(Array) ? q : [q, 1]
      end

      all_queues_have_same_priority = @queues.map { _1[1] }.uniq.size == 1
      @queues_filter = @queues.map(&:first) if all_queues_have_same_priority
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

        if (@work_queue.size < @max_concurrency) && (job = next_job)
          @work_queue.push(job)
        else
          sleep polling_interval
        end
      end

      puts "Exiting."
    end

    protected

    def next_job
      job = check_for_jobs
      return nil unless job

      reserve_job(job) || nil
    end

    def check_for_jobs
      query = Models::Job.where(state: "ready").
        where { (next_execution_at =~ nil) | (next_execution_at <= Time.now) }.
        or(state: "failed", next_execution_at: (..Time.now)).
        where(reserved_by: nil)

      if queues.empty?
        logger.info "Checking all queues"
      else
        queues_to_check = queues_filter
        query = query.where(queue: queues_to_check)
        logger.info "Checking queues #{queues_to_check}"
      end

      query.first
    end

    def queues_filter
      return @queues_filter if @queues_filter

      # Weighted random sampling from Efraimidis and Spirakis, thanks to https://gist.github.com/O-I/3e0654509dd8057b539a
      queue_to_check, _priority = queues.max_by(1) { |(_name, priority)| rand ** (1.0 / priority) }.first
      [queue_to_check]
    end

    def reserve_job(job)
      updated_count = Models::Job.where(id: job.id, reserved_by: nil).update(reserved_by: worker_id)
      updated_count == 1 ? job : false
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
