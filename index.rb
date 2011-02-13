require 'http'
require 'frucnatra'

get '/' do
  "<h1>Fructose Demo</h1>
  <p>
    <form method='post' action='#{$root}/name/submit'>
      What's your name?
      <input type='text' name='name'>
      <input type='submit'>
    </form>
  </p>
  <ul>
    <li><a href='#{$root}/test'>Test page</a></li>
    <li><a href='#{$root}/lskdjfklsjdf'>Non-existent page</a></li>
  </ul>"
end

post '/name/submit' do
  # No .escape will cause an error
  "<h1>Fructose Demo</h1>
  <p>You said your name was #{params[:name].escape}</p>
  <p><a href='#{$root}'>Go home</a></p>"
end

get '/test' do
  "<h1>Fructose Demo</h1>
  <p>This is a test page!</p>
  <p><a href='#{$root}'>Go home</a></p>"
end

get '/name/:name' do
  "You said your name was #{params[:name]}"
end