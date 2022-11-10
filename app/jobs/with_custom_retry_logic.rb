class Jobs::WithCustomRetryLogic < Gator::Queueable
  queue_on :custom
  retry_with do |exception, retry_count|
    [10, 20, 30][retry_count] || false
  end

  def handle(*)
    logger.warn "Going to fail..."
    raise "Always fails"
  end
end