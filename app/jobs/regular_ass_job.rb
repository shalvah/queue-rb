class Jobs::RegularAssJob < Gator::Queueable
  def handle(*)
    DB[:jobs].where(next_job_id: 'ready').count
    sleep(rand(5))
  end
end