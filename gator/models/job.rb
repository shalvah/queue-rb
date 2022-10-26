require 'json'

require_relative "../../lib/db"

module Gator
  module Models
    class Job < Sequel::Model
      def before_create
        self.id = "job_" + SecureRandom.hex(12)
        self.args = self[:args].to_json
      end

      def args = JSON.parse(self[:args])
    end
  end
end