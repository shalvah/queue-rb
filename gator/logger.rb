require "logger"
require 'delegate'

module Gator
  class Logger < DelegateClass(::Logger)
    def initialize
      @logger = ::Logger.new(STDERR)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity} [#{datetime.strftime "%Y-%m-%d %H:%M:%S"}] #{fc :green, msg}\n"
      end
      super(@logger)
    end

    private

    # Shout out to https://gist.github.com/paul-appsinyourpants/834555
    COLOR_ESCAPES = {
      :none => 0,
      :bright => 1,
      :black => 30,
      :red => 31,
      :green => 32,
      :yellow => 33,
      :blue => 34,
      :magenta => 35,
      :cyan => 36,
      :white => 37,
      :default => 39,
    }

    # Text color
    def fc(clr, text = nil)
      "\x1B[" + (COLOR_ESCAPES[clr] || 0).to_s + 'm' + (text ? text + "\x1B[0m" : "")
    end

    # Background color
    def bc(clr, text = nil)
      "\x1B[" + ((COLOR_ESCAPES[clr] || 0) + 10).to_s + 'm' + (text ? text + "\x1B[0m" : "")
    end
  end
end