require :http
require :phpcall

$routes = {}

def get(path, &block)
  $routes[path] = {} if $routes[path].nil?
  $routes[path][:get] = block
end

def post(path, &block)
  $routes[path] = {} if $routes[path].nil?
  $routes[path][:post] = block
end

def frucnatra_shutdown
  puts "Frucnatra doesn't know this ditty."
  # block.call
end

phpcall register_shutdown_function 'frucnatra_shutdown'