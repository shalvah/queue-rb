require "securerandom"
require_relative "./logger"
require_relative './models/job'

module Gator
  class Worker
    attr_reader :polling_interval, :logger, :worker_id

    def initialize(**opts)
      super
      @polling_interval = 5
      @logger = Gator::Logger.new
      @worker_id = "wrk_" + SecureRandom.hex(8)
    end

    def run
      logger.info "Worker #{worker_id} ready"

      loop do
        if (job = next_job)
          error = execute_job(job)
          cleanup(job, error)
        else
          sleep polling_interval
        end
      end
    end

    def next_job
      job = check_for_jobs
      return nil unless job

      reserve_job(job) || nil
    end

    def check_for_jobs
      query = Models::Job.where(state: "waiting", reserved_by: nil)
      query.where { (next_execution_at =~ nil) | (next_execution_at <= Time.now) }
      # logger.info query.sql
      query.first
    end

    def reserve_job(job)
      updated_count = Models::Job.where(id: job.id, reserved_by: nil).update(reserved_by: worker_id)
      updated_count == 1 ? job : false
    end

    def execute_job(job)
      Object.const_get(job.name).new.handle(*job.args)
      logger.info "Processed job id=#{job.id} result=succeeded args=#{job.args}"
      nil
    rescue => e
      logger.info "Processed job id=#{job.id} result=failed args=#{job.args}"
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