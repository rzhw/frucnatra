require 'frucnatra'

@home = "<p><a href='#{root}'>Go home</a></p>"

get '/' do
  "<h1>Fructose Demo</h1>  
  <h2>Basic</h2>
  <ul>
    <li><a href='#{root}/test'>Test page</a></li>
    <li><a href='#{root}/lskdjfklsjdf'>Non-existent page</a></li>
  </ul>
  
  <h2>POST</h2>
  <p>
    <form method='post' action='#{root}/name/submit'>
      Your name:
      <input type='text' name='name'>
      <input type='submit' value='Submit'>
    </form>
  </p>
  
  <h2>Route params</h2>
  <p>
    Your name:
    <input type='text' id='name-p'>
    <input type='button' value='Submit' onclick='location.href=\"#{root}/name/param/\" + document.getElementById(\"name-p\").value'>
    <noscript>(need js enabled)</noscript>
  </p>
  
  <h2>Multiple route params</h2>
  <p>
    First name:
    <input type='text' id='name-f'>
    Last name:
    <input type='text' id='name-l'>
    <input type='button' value='Submit' onclick='location.href=\"#{root}/name/param/\" +
      document.getElementById(\"name-f\").value + \"/\" + document.getElementById(\"name-l\").value'>
    <noscript>(need js enabled)</noscript>
  </p>"
end

get '/test' do
  "<h1>Fructose Demo</h1>
  <p>This is a test page!</p>" + @home
end

post '/name/submit' do
  "<h1>Fructose Demo</h1>
  <p>You said your name was #{params[:name]}</p>" + @home
end

get '/name/param/:name' do
  "<h1>Fructose Demo</h1>
  <p>You said your name was #{params[:name]}" + @home
end

get '/name/param/:first/:last' do
  "<h1>Fructose Demo</h1>
  <p>You said your name was #{params[:first]} #{params[:last]}" + @home
end