
require_relative "./logger"
require_relative "./models/job"

module Gator
  class Queueable
    include Configuration

    def self.dispatch(*args, wait: nil, at: nil, queue: nil)
      job = Gator::Models::Job.new(
        name: self.name, args:,
        next_execution_at: wait ? (Time.now + wait) : (at ? at : nil),
        queue: queue ? queue : (self.queue || 'default'),
      )
      job.save
      Gator::Logger.new.info "Enqueued job id=#{job.id} args=#{job.args} queue=#{job.queue}"
    end

    def self.dispatch_many(args, wait: nil, at: nil, queue: nil)
      next_execution_at = wait ? (Time.now + wait) : (at ? at : nil)
      queue = queue ? queue : (self.queue || 'default')

      jobs = args.map do |job_args|
        {
          id: Gator::Models::Job.generate_job_id,
          name: self.name,
          args: job_args.to_json,
          next_execution_at:,
          queue: queue.to_s,
        }
      end

      # DB.loggers << Gator::Logger.new
      Gator::Models::Job.multi_insert(jobs)

      Gator::Logger.new.info "Enqueued #{args.size} #{self.name} jobs queue=#{queue}"
    end

    attr_reader :logger, :retry_count, :job_id

    def initialize
      @logger = Gator::Logger.new
    end
  end
end