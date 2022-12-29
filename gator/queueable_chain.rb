require_relative "./logger"
require_relative "./models/job"

module Gator
  class QueueableChain
    include Queueable::Configuration

    class << self
      attr_reader :component_jobs

      def jobs(jobs)
        @component_jobs = jobs
      end
    end

    def self.dispatch(*args, wait: nil, at: nil, queue: nil)
      at ||= wait ? (Time.now + wait) : nil
      chain_queue = queue || self.queue

      chain_id = SecureRandom.hex(12)
      jobs = component_jobs.map do |job_class|
        {
          'id' => Gator::Models::Job.generate_job_id,
          'name' => job_class.name,
          'args' => args,
          'queue' => chain_queue || job_class.queue || 'default',
          'chain_class' => self.name,
        }
      end

      $redis.multi do |transaction|
        Gator::Models::Job.save(
          jobs.shift.merge({ 'chain_id' => chain_id }), at:,
          connection: transaction
        )
        transaction.rpush "chains-#{chain_id}", jobs.map(&:to_json)
      end

      Gator::Logger.new.info "Enqueued chain #{self.name} queue=#{queue}"
    end
  end
end