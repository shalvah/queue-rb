class Jobs::DoSomeStuff < Gator::Queueable
  queue_on :high

  with_middleware [
    Jobs::Middleware::SayGoodbye,
    Jobs::Middleware::MeasureExecutionTime
  ]

  on_error do |job|
    job.logger.error "Oh no, there's a problem with job #{job.job_id}!"
  end

  def handle(arg1, arg2 = nil)
    sleep 1.5
    sleep 1.5
    sleep 1.5
    raise "Big ugly error" if rand > 0.8
    logger.info "HIIII #{arg1} and #{arg2}"
  end
end