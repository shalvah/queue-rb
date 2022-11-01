
require_relative "./logger"
require_relative "./models/job"

module Gator
  class Queueable
    def self.dispatch(*args, **options)
      job = Gator::Models::Job.new(name: self.name, args:)
      job.save
      Gator::Logger.new.info "Enqueued job id=#{job.id} args=#{job.args}"
    end

    def self.dispatch_many(args, **options)
      jobs = args.map do |job_args|
        {
          id: Gator::Models::Job.generate_job_id,
          name: self.name,
          args: job_args.to_json,
        }
      end
      Gator::Models::Job.multi_insert(jobs)

      Gator::Logger.new.info "Enqueued #{args.size} #{self.name} jobs"
    end

    attr_reader :logger

    def initialize
      super
      @logger = Gator::Logger.new
    end
  end
end