require :http
require :phpcall

$routes = {}

def get(path, &block)
  route :get, path, &block
end

def post(path, &block)
  route :post, path, &block
end

def route(method, path, &block)
  $routes[path] ||= {}
  $routes[path][method] = block
end

def frucnatra_shutdown
  route = server[:PATH_INFO].nil? ? '/' : server[:PATH_INFO].escape
  
  if $routes.has_key? route
    puts 'wat'
    # block.call
  else
    puts "<!DOCTYPE html>
<html>
<head>
  <style type=\"text/css\">
  body { text-align:center;font-family:helvetica,arial;font-size:22px;
    color:#888;margin:20px}
  #c {margin:0 auto;width:500px;text-align:left}
  </style>
</head>
<body>
  <h2>Frucnatra doesn't know this ditty.</h2>
  <img src='/__sinatra__/404.png'>
  <div id=\"c\">
    Try this:
    <pre>get '#{route}' do
  \"Hello World\"
end</pre>

  </div>
</body>
</html>"
  end
end

# The nil is required since every Fructose function takes a block as its first param
phpcall :register_shutdown_function, 'F_frucnatra_shutdown', nil