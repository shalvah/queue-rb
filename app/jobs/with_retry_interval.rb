class Jobs::WithRetryInterval < Gator::Queueable
  queue_on :interval
  retry_with interval: 2 * 60, queue: :retries

  def handle(*)
    logger.warn "Going to fail..."
    raise "Always fails"
  end
end