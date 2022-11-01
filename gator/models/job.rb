require 'json'

require_relative "../../lib/db"

module Gator
  module Models
    class Job < Sequel::Model
      def before_create
        self.id = Job.generate_job_id
        self.args = self[:args].to_json
      end

      def args = JSON.parse(self[:args])

      def self.generate_job_id
        "job_" + SecureRandom.hex(12)
      end
    end
  end
end