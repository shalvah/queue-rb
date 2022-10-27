
require 'optparse'

options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: bin/work.rb [options]"

  parser.on("-rFILE", "--require", "File to load at startup. Use this to boot your app.") do |r|
    options[:require] = r
  end

  parser.on("-h", "--help", "Prints this help") do
    puts parser
    exit
  end
end.parse!

if options[:require]
  require options[:require]
end

require_relative '../worker'

w = Gator::Worker.new
w.run