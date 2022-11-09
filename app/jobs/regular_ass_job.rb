class Jobs::RegularAssJob < Gator::Queueable
  def handle(*)
    sleep(rand(3))
  end
end