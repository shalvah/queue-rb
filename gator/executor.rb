# frozen_string_literal: true

module Gator
  class Executor
    def self.execute(job_details)
      new(job_details).run
    end

    attr_reader :job_details, :logger

    def initialize(job_details)
      @job_details = job_details
      @logger = Gator::Logger.new(level: ::Logger::INFO)
    end

    def run
      job_class = Object.const_get(job_details.name)
      error = execute_job(job_details, job_class)
      cleanup(job_details, job_class, error)
    end

    protected

    def execute_job(job, job_class)
      logger.info "Processing job id=#{job.id} class=#{job_class} queue=#{job.queue}"
      middleware = job_class.middleware || []
      job_instance = job_class.new(job_id: job.id, retry_count: job.attempts, chain_class: job.chain_class)
      executor = proc do
        next_middleware = middleware.shift
        next_middleware ? next_middleware.call(job_instance, &executor) : job_instance.handle(*job.args)
      end
      executor.call

      logger.info "Processed job id=#{job.id} result=succeeded class=#{job_class} queue=#{job.queue}"
      nil
    rescue => e
      logger.info "Processed job id=#{job.id} result=failed queue=#{job.queue}"
      run_job_error_handler(job_instance, e) if e
      e
    end

    def run_job_error_handler(job_instance, error)
      error_handler = Object.const_get(job_instance.chain_class).error_handler if job_instance.chain_class
      error_handler ||= job_instance.class.error_handler
      return unless error_handler

      error_handler.call(job_instance, error)
    rescue => e
      logger.warn "Job error handler threw an error: #{e.message}"
    end

    def cleanup(job, job_class, error = nil)
      job.attempts += 1
      job.last_executed_at = Time.now
      if error
        job.state = "failed"
        job.error_details = error
        job_class.retry_strategy ? set_retry_details(job_class.retry_strategy, job, error) : (job.state = "dead")
      else
        job.state = "succeeded"
      end

      if job.state == "failed"
        $redis.zadd "retry", job.next_execution_at.to_i, job.to_h.to_json
      elsif job.state == "dead"
        $redis.rpush "dead", job.to_h.to_json
      elsif job.chain_id
        next_job = $redis.lpop "chains-#{job.chain_id}"
        if next_job
          Gator::Models::Job.save(JSON(next_job).merge({ 'chain_id' => job.chain_id }))
        end
      end
    end

    def set_retry_details(retry_strategy, job, error)
      retry_strategy => { interval:, queue:, max_retries:, block: }

      retry_count = job.attempts - 1
      if max_retries && retry_count >= max_retries
        job.state = "dead"
        return
      end

      if block
        decision = block.call(error, retry_count)
        if decision == false
          job.state = "dead"
          return
        end

        interval = decision
      end

      interval = (30 + (retry_count) ** 5) if interval == :exponential
      job.next_execution_at = job.last_executed_at + interval

      job.queue = queue if queue
    end
  end
end

def cleanup(job, job_class, error = nil)
  job.attempts += 1
  job.last_executed_at = Time.now
  if error
    job.state = "failed"
    job.error_details = error
    job_class.retry_strategy ? set_retry_details(job_class.retry_strategy, job, error) : (job.state = "dead")
  else
    job.state = "succeeded"
  end

  if job.state == "failed"
    $redis.zadd "retry", job.next_execution_at.to_i, job.to_h.to_json
  elsif job.state == "dead"
    $redis.rpush "dead", job.to_h.to_json
  elsif job.chain_id
    next_job = $redis.lpop "chains-#{job.chain_id}"
    if next_job
      Gator::Models::Job.save(JSON(next_job).merge({ 'chain_id' => job.chain_id }))
    end
  end
end