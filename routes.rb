require "sinatra"
require_relative "./jobs/do_some_stuff"

get "/queue/:count?" do
  count = params[:count] || 1
  count.times do |i|
    DoSomeStuff.dispatch("Nellie #{i}", "Buster #{i}")
  end
  "Queued #{count} jobs"
end