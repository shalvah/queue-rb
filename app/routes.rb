require_relative "./boot"

require 'sinatra/base'

class App < Sinatra::Base
  get "/queue/:count?" do
    count = Integer(params[:count] || 1)
    count.times do |i|
      Jobs::DoSomeStuff.dispatch("Nellie #{i}", "Buster #{i}")
    end
    "Queued #{count} jobs"
  end
end

App.run! if App.app_file == $0