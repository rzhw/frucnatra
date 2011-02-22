$using_frucnatra = true # Change this to run on Sinatra

if !$using_frucnatra
  require 'rubygems'
  require 'sinatra'
else
  require 'frucnatra'
end

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

get '/redirect' do
  redirect "#{url_root}/redirected"
end

get '/redirected' do
  "You just got redirected!"
end