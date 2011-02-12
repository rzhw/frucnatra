require 'http'
require 'frucnatra'

get '/' do
  "<h1>Test</h1>
  <p>This is the homepage!</p>
  <ul>
    <li><a href='#{$root}/test'>Test page</a></li>
    <li><a href='#{$root}/lskdjfklsjdf'>Non-existent page</a></li>
  </ul>"
end

get '/test' do
  "<h1>Test</h1>
  <p>This is a test page!</p>
  <p><a href='#{$root}'>Go home</a></p>"
end

get '/name/:name' do
  "You said your name was #{params[:name]}"
end