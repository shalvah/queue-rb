class Jobs::DoSomeStuff < Gator::Queueable
  def handle(arg1, arg2 = nil)
    sleep 1.5
    raise "Oh no, a problem" if rand > 0.8
    logger.info "HIIII #{arg1} and #{arg2}"
  end
end