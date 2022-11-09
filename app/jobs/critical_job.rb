class Jobs::CriticalJob < Gator::Queueable
  queue_on :critical

  def handle(*)
    sleep(rand(3))
  end
end