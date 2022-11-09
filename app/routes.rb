require_relative "./boot"

require 'sinatra/base'

class App < Sinatra::Base
  get "/bulk/:count" do
    count = Integer(params[:count])
    args = count.times.map { |i| ["Nellie #{i}", "Buster #{i}"] }
    Jobs::DoSomeStuff.dispatch_many(args)
    "Queued #{count} jobs"
  end

  get "/delay/:delay?" do
    delay = Integer(params[:delay] || 3) * 60
    Jobs::DoSomeStuff.dispatch("I was dispatched #{delay} minutes ago — at #{Time.now}", wait: delay)

    "Queued 1 job"
  end

  get "/queue/:queue?" do
    3.times { Jobs::RegularAssJob.dispatch("arg") }
    Jobs::CriticalJob.dispatch
    Jobs::RegularAssJob.dispatch_many([["arg"]] * 4, queue: :critical)

    "Queued 1 job"
  end
end

App.run! if App.app_file == $0