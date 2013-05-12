require 'sinatra'
enable :sessions
get '/' do
  if not session.has_key?(:message) then
    session[:message] = 0
  else
    session[:message] += 1
  end
  "count: #{session[:message]}"
end
