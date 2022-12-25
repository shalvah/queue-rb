
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
      next_execution_at = wait ? (Time.now + wait) : (at ? at : nil)
      chain_queue = queue ? queue : self.queue

      jobs = []
      logs = []
      component_jobs.reverse_each.with_index do |job_class, index|
        is_first_in_chain = (index == component_jobs.size - 1)
        queue = (chain_queue || job_class.queue || 'default').to_s
        jobs << {
          id: Gator::Models::Job.generate_job_id,
          name: job_class.name,
          args: args.to_json,
          next_execution_at: is_first_in_chain ? next_execution_at : nil,
          state: is_first_in_chain ? "ready" : "waiting",
          queue:,
          next_job_id: (jobs.last[:id] rescue nil),
        }
        logs << ["Enqueued job #{job_class.name} in chain #{self.name} queue=#{queue}"]
      end

      Gator::Models::Job.multi_insert(jobs.reverse!)

      Gator::Logger.new.info logs.join("\n")
    end
  end
end