require_relative "../gator/job"

class DoSomeStuff < Gator::Job
  def handle(arg1, arg2 = nil)
    logger.info "HIIII #{arg1} and #{arg2}"
  end
end