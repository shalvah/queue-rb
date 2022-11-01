require_relative "./boot"

require 'sinatra/base'

class App < Sinatra::Base
  get "/queue/:count?" do
    Jobs::DoSomeStuff.dispatch("Nellie", "Buster")

    count = Integer(params[:count] || 1)
    args = count.times.map { |i| ["Nellie #{i}", "Buster #{i}"] }
    Jobs::DoSomeStuff.dispatch_many(args)

    delay = count % 15
    Jobs::DoSomeStuff.dispatch("I was dispatched #{delay} minutes ago — at #{Time.now}", wait: delay * 60)

    "Queued #{count + 1} jobs"
  end
end

App.run! if App.app_file == $0