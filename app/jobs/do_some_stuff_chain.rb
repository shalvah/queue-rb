# frozen_string_literal: true

class Jobs::DoSomeStuffChain < Gator::QueueableChain
  on_error do |job|
    job.logger.error "Error in job #{job.class.name} in chain #{self.name}"
  end

  jobs [
    Jobs::DoSomeStuff,
    Jobs::RegularAssJob,
    Jobs::DoSomeStuff,
  ]
end
