require "securerandom"
require_relative "./logger"
require_relative './models/job'

module Gator
  class Worker
    attr_reader :polling_interval, :logger, :worker_id, :queues

    def initialize(queues: [])
      @polling_interval = 5
      @logger = Gator::Logger.new(level: ::Logger::INFO)
      @worker_id = "wrk_" + SecureRandom.hex(8)
      @queues = (queues || []).map do |q|
        q.kind_of?(Array) ? q : [q, 1]
      end

      all_queues_have_same_priority = @queues.map { _1[1] }.uniq.size == 1
      @queues_filter = @queues.map(&:first) if all_queues_have_same_priority
    end

    def run
      logger.info "Worker #{worker_id} ready"
      queues.empty? ?
        logger.info("Watching all queues") :
        logger.info("Watching queues: #{queues.map { |q, p| "#{q} (priority=#{p})" }.join(', ')}")

      loop do
        if (job = next_job)
          error = execute_job(job)
          cleanup(job, error)
        else
          sleep polling_interval
        end
      end
    end

    protected

    def next_job
      job = check_for_jobs
      return nil unless job

      reserve_job(job) || nil
    end

    def check_for_jobs
      query = Models::Job.where(state: "waiting", reserved_by: nil)
      query = query.where { (next_execution_at =~ nil) | (next_execution_at <= Time.now) }

      if queues.empty?
        logger.info "Checking all queues"
      else
        queues_to_check = queues_filter
        query = query.where(queue: queues_to_check)
        logger.info "Checking queues #{queues_to_check}"
      end

      logger.debug query.sql
      query.first
    end

    def queues_filter
      return @queues_filter if @queues_filter

      # Weighted random sampling from Efraimidis and Spirakis, thanks to https://gist.github.com/O-I/3e0654509dd8057b539a
      queue_to_check, _priority = queues.max_by(1) { |(_name, priority)| rand ** (1.0/priority) }.first
      [queue_to_check]
    end

    def reserve_job(job)
      updated_count = Models::Job.where(id: job.id, reserved_by: nil).update(reserved_by: worker_id)
      updated_count == 1 ? job : false
    end

    def execute_job(job)
      Object.const_get(job.name).new.handle(*job.args)
      logger.info "Processed job id=#{job.id} result=succeeded queue=#{job.queue}"
      nil
    rescue => e
      logger.info "Processed job id=#{job.id} result=failed queue=#{job.queue}"
      e
    end

    def cleanup(job, error = nil)
      job.reserved_by = nil
      job.attempts += 1
      job.last_executed_at = Time.now
      job.state = error ? "failed" : "succeeded"
      job.error_details = error if error
      job.save
    end
  end
end