module Jobs
  module Middleware
    class SayGoodbye
      def self.call(job)
        yield
        job.logger.info("Goodbye from job #{job.class.name}")
      end
    end
  end
end