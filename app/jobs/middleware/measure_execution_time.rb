module Jobs
  module Middleware
    class MeasureExecutionTime
      def self.call(job)
        start_time = Process::clock_gettime(Process::CLOCK_MONOTONIC)
        yield
        end_time = Process::clock_gettime(Process::CLOCK_MONOTONIC)
        job.logger.info("Took #{end_time - start_time} seconds")
      end
    end
  end
end