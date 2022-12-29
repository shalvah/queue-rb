
require_relative "./logger"
require_relative "./models/job"

module Gator
  class Queueable
    include Configuration

    def self.dispatch(*args, wait: nil, at: nil, queue: nil, connection: nil)
      at ||= wait ? (Time.now + wait) : nil
      queue ||= self.queue || 'default'
      job_hash = {
        'id' => Gator::Models::Job.generate_job_id,
        'name' => self.name,
        'args' => args,
        'queue' => queue,
      }
      Gator::Models::Job.save(job_hash, at:, connection:)
      Gator::Logger.new.info "Enqueued job id=#{job_hash['id']} args=#{args} queue=#{queue}"
    end

    def self.dispatch_many(args, wait: nil, at: nil, queue: nil)
      next_execution_at = wait ? (Time.now + wait) : (at ? at : nil)
      queue ||= self.queue

      $redis.multi do |transaction|
        args.each do |job_args|
          dispatch(*job_args, at: next_execution_at, queue:, connection: transaction)
        end
      end
    end

    attr_reader :logger, :retry_count, :job_id, :chain_class

    def initialize(job_id:, retry_count: 0, chain_class: nil)
      @logger = Gator::Logger.new
      @job_id = job_id
      @retry_count = retry_count
      @chain_class = chain_class
    end
  end
end