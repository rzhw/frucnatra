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
  # phpcall :print_r, server
  route = server[:PATH_INFO].nil? ? '/' : server[:PATH_INFO].escape
  puts "<p>Frucnatra doesn't know this ditty.<p>Route: #{route}"
  # block.call
end

# The nil is required since every Fructose function takes a block as its first param
phpcall :register_shutdown_function, 'F_frucnatra_shutdown', nil