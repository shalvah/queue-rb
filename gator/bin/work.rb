# frozen_string_literal: true

require 'optparse'

options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: bin/work.rb [options]"

  parser.on("-r", "--require FILE", "File to load at startup. Use this to boot your app.")

  parser.on("-q", "--queue QUEUE", Array,
    "A queue for this worker to check. Pass this flag multiple times to set multiple queues. " +
      "Separate a queue from its priority with a comma. Example: '-q critical,8 -q default,1'"
  ) do |q, priority|
    options[:queue] ||= []
    options[:queue] << [q, priority ? Integer(priority) : 1]
  end
end.parse!(into: options)

require options.delete(:require) if options[:require]

require_relative '../worker'

options[:queues] = options.delete(:queue)

w = Gator::Worker.new(**options)
w.run