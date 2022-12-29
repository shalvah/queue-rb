require 'json'

require_relative "../../lib/redis"

module Gator
  module Models
    class Job
      def self.save(details, at: nil, connection: nil)
        connection ||= $redis
        if at
          connection.zadd "scheduled", at.to_i, details.to_json
        else
          connection.rpush "queue-#{details['queue']}", details.except('queue').to_json
        end

        connection.sadd "known-queues", details['queue']
      end

      def self.generate_job_id
        "job_" + SecureRandom.hex(12)
      end
    end
  end
end
