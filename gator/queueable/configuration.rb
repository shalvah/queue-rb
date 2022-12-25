module Gator
  class Queueable
    module Configuration
      def self.included(host)
        host.extend ClassMethods
      end

      module ClassMethods
        attr_reader :queue, :retry_strategy, :middleware, :error_handler

        protected
        def queue_on(queue)
          @queue = queue
        end

        def retry_with(interval: nil, max_retries: 10, queue: nil, &block)
          @retry_strategy = { interval:, max_retries:, queue:, block: }
        end

        def on_error(&handler)
          @error_handler = handler
        end

        def with_middleware(middleware)
          @middleware = Array(middleware)
        end
      end
    end
  end
end