require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir("app")

module Gator; end

loader.push_dir("gator", namespace: Gator)
loader.setup

require_relative "../lib/db"