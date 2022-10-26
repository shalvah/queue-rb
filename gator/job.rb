
require_relative "./logger"
require_relative "./models/job"

module Gator
  class Job
    def self.dispatch(*args, **options)
      job = Gator::Models::Job.new(name: self.name, args:)
      job.save
      Gator::Logger.new.info "Enqueued job #{job.id} with args #{job.args}"
    end

    attr_reader :logger

    def initialize
      super
      @logger = Gator::Logger.new
    end
  end
end