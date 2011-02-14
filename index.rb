require 'frucnatra'

get '/' do
  render 'home'
end

get '/test' do
  "This is a test page!"
end

post '/name/submit' do
  "You said your name was #{params[:name]}"
end

get '/name/:name' do
  "You said your name was #{params[:name]}"
end

get '/name/:first/:last' do
  "You said your name was #{params[:first]} #{params[:last]}"
end