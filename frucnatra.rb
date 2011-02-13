require 'http'
require 'phpcall'

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

  def put(path, &bk)     route 'PUT',     path, &bk end
  def post(path, &bk)    route 'POST',    path, &bk end
  def delete(path, &bk)  route 'DELETE',  path, &bk end
  def head(path, &bk)    route 'HEAD',    path, &bk end
  def options(path, &bk) route 'OPTIONS', path, &bk end

  def route(verb, path, &block)  
    #pattern = path
    #keys = nil
    #conditions = nil
    
    options = {}
    dummy_block, pattern, keys, conditions = compile! verb, path, nil, options
    
    #($routes[verb] ||= []).
    #  push([pattern, keys, conditions, block]).last
    
    count = phpcall :count, $routes[verb] # Fructose doesn't seem to support array length yet
    $routes[verb][count] = [pattern, keys, conditions, Proc.new(&block)] # Using Proc.new as a temp Fructose-related thing
  end
  
  def compile!(verb, path, block, options) # options={}
    #options.each_pair { |option, args| send(option, *args) }
    #method_name = "#{verb} #{path}"

    #define_method(method_name, &block)
    #unbound_method          = instance_method method_name
    pattern, keys           = compile(path)
    #conditions, @conditions = @conditions, []
    conditions = []
    #remove_method method_name
    
    #[ block.arity != 0 ?
    #    proc { unbound_method.bind(self).call(*@block_params) } :
    #    proc { unbound_method.bind(self).call },
    #  pattern, keys, conditions ]
    
    [ block,
      pattern, keys, conditions ]
  end

  def compile(path)
    keys = []
    if path.respond_to? :to_s
      special_chars = %w{. + ( ) $}
      pattern =
        path.to_s.gsub(/((:\w+)|[\*#{special_chars.join}])/) do |match|
          case match
          when "*"
            keys << 'splat'
            "(.*?)"
          when special_chars #when *special_chars
            Regexp.escape(match)
          else
            keys << $2[1..-1]
            "([^/?#]+)"
          end
        end
      [/^#{pattern}$/, keys]
    elsif path.respond_to?(:keys) && path.respond_to?(:match)
      [path, path.keys]
    elsif path.respond_to? :match
      [path, keys]
    else
      #raise TypeError, path
    end
  end
  
  def frucnatra_shutdown
    path_info = $server[:PATH_INFO] || '/'
    method = $server[:REQUEST_METHOD]
    
    if routes = $routes[method]
      routes.each do |arr| # Splatting to block params not supported yet
        pattern, keys, conditions, block = arr

        if match = pattern.match(path_info)
          values = match.captures.to_a
          params =
            if keys.any?
              keys.zip(values).inject({}) do |hash,a| # |hash,(k,v)|
                k,v = a
                if k == 'splat'
                  (hash[k] ||= []) << v
                else
                  hash[k] = v
                end
                hash
              end
            elsif values.any?
              {'captures' => values}
            else
              {}
            end
          
          # Untaint the params before insertion - Sinatra doesn't have tainting
          $request.each do |k,v|
            params = params.merge({ k => v.untaint })
          end
        
          # Workaround for NodeType SelfReference not supported yet (in the compile! method)
          define_global_method :params do
            params
          end
          
          puts block.call
          return
        end
      end
    end
    
    puts (<<-HTML).gsub(/^ {6}/, '')
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

  phpcall :register_shutdown_function, 'F_frucnatra_shutdown', nil
#end