class Jobs::WithExponentialRetry < Gator::Queueable
  queue_on :exponential
  retry_with interval: :exponential, max_retries: 4

  def handle(*)
    logger.warn "Going to fail..."
    raise "Always fails"
  end
end