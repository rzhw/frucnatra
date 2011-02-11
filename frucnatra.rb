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
  $routes[path] = {} if $routes[path].nil?
  $routes[path][method] = block
end

def frucnatra_shutdown
  puts "Frucnatra doesn't know this ditty."
  # block.call
end

phpcall :register_shutdown_function, 'F_frucnatra_shutdown'