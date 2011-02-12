require :http
require :phpcall

#module Frucnatra
  $routes = Hash.new do |h,k|
    h[k] = []
  end

  #$routes = []

  # In Sinatra this may be :root in the Base class, not sure
  $root = $server[:REQUEST_URI][0, $server[:REQUEST_URI].length - ($server[:PATH_INFO].nil? ? 0 : $server[:PATH_INFO].length)]

  def get(path, &block)
    route 'GET', path, &block
  end

  def put(path, &bk)     route 'PUT',     path, opts, &bk end
  def post(path, &bk)    route 'POST',    path, opts, &bk end
  def delete(path, &bk)  route 'DELETE',  path, opts, &bk end
  def head(path, &bk)    route 'HEAD',    path, opts, &bk end
  def options(path, &bk) route 'OPTIONS', path, opts, &bk end

  def route(verb, path, &block)  
    pattern = path
    keys = nil
    conditions = nil
    
    #($routes[verb] ||= []).
    #  push([pattern, keys, conditions, Proc.new(&block)]).last
    
    count = phpcall :count, $routes[verb] # Fructose doesn't seem to support array length yet
    $routes[verb][count] = [pattern, keys, conditions, Proc.new(&block)] # Using Proc.new as a temp Fructose-related thing
  end

  def frucnatra_shutdown
    path_info = $server[:PATH_INFO] || '/'
    method = $server[:REQUEST_METHOD]
    
    route_found = false # temp
    
    if routes = $routes[method]
      routes.each do |arr| # Splatting to block params not supported yet
        pattern, keys, conditions, block = arr

        if pattern == path_info
          puts block.call
          route_found = true
        end
      end
    end
    
    if !route_found
      # This is meant to be (<<-HTML).gsub(/^ {8}/, ''), but Fructose doesn't support regex yet
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
#end