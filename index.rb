$using_frucnatra = true # Change this to run on Sinatra

if !$using_frucnatra
  require 'rubygems'
  require 'sinatra'
  def url_root
    ''
  end
else
  require 'frucnatra'
end

enable :sessions

get '/' do
  erb :home
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

get '/request' do
  request.path_info
end

post '/session/set' do
  session[params[:name]] = params[:val]
  "Set!"
end

post '/session/get' do
  if not session[params[:name]].nil?
    "#{params[:name]}: #{session[params[:name]]}"
  else
    "#{params[:name]}: <em>nil</em>"
  end
end