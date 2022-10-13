require "sinatra"

get "/queue/:count?" do
  # Queue jobs
  "Queued #{params[:count] || 1} jobs"
end