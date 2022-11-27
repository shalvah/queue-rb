module Gator
  class Queueable
    module Configuration
      def self.included(host)
        host.extend ClassMethods
      end

      module ClassMethods
        protected

        attr_reader :queue, :retry_strategy

        def queue_on(queue)
          @queue = queue
        end

        def retry_with(interval: nil, max_retries: 10, queue: nil, &block)
          @retry_strategy = { interval:, max_retries:, queue:, block: }
        end
      end
    end
  end
end