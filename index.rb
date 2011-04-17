$using_frucnatra = false # Change this to run on Sinatra

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
  session[params[:sessionset_name]] = params[:sessionset_val]
  "Set!"
end

post '/session/get' do
  if not session[params[:sessionget_name]].nil?
    "#{params[:sessionget_name]}: #{session[params[:sessionget_name]]}"
  else
    "#{params[:sessionget_name]}: <em>nil</em>"
  end
end