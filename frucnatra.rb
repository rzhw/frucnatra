require :http
require :phpcall

$routes = {}

def get(path, &block)
  route 'GET', path, &block
end

def post(path, &block)
  route 'POST', path, &block
end

def route(method, path, &block)
  $routes[path] ||= {}
  $routes[path][method] = block
end

def frucnatra_shutdown
  path_info = server[:PATH_INFO] || '/'
  method = server[:REQUEST_METHOD]
  
  if $routes.has_key? path_info and $routes[path_info].has_key? method
    puts $routes[path_info][method].call
  else
    # This is meant to be (<<-HTML).gsub(/^ {6}/, ''), but Fructose doesn't support regex yet
    puts (<<-HTML)
      <!DOCTYPE html>
      <html>
      <head>
        <style type="text/css">
        body { text-align:center;font-family:helvetica,arial;font-size:22px;
          color:#888;margin:20px}
        #c {margin:0 auto;width:500px;text-align:left}
        </style>
      </head>
      <body>
        <h2>Frucnatra doesn't know this ditty.</h2>
        <img src='/__sinatra__/404.png'>
        <div id="c">
          Try this:
          <pre>#{method.downcase.escape} '#{path_info.escape}' do\n  "Hello World"\nend</pre>
        </div>
      </body>
      </html>
    HTML
  end
end

phpcall :register_shutdown_function, 'F_frucnatra_shutdown', nil

get '/' do
  "Hello world!"
end