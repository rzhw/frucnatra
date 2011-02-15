require 'http'
require 'phpcall'

#module Frucnatra
  # Methods available to routes, before/after filters, and views.
  #module Helpers
    def status(value)
      phpcall :header, "Status: HTTP/1.1 #{$frucnatra_statustext[value]}"
    end
    
    def redirect(uri)
      status 302
      phpcall :header, "Location: #{uri}"
      halt
    end
  #end
  
  $routes = Hash.new do |h,k|
    h[k] = []
  end
          
  # Frucnatra isn't a DSL, so this is needed
  request_uri_decoded = phpcall :urldecode, $server[:REQUEST_URI]
  $root = request_uri_decoded[0, request_uri_decoded.length - ($server[:PATH_INFO].nil? ? 0 : $server[:PATH_INFO].length)]
  define_global_method :root do
    $root
  end
  
  def halt
    `exit();`
  end

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
    
    $routes[verb][$routes[verb].count] = [pattern, keys, conditions, Proc.new(&block)] # Using Proc.new as a temp Fructose-related thing
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
  
  $frucnatra_dir = phpcall :realpath, '.' # Workaround since the working dir is incorrect in blocks
  $frucnatra_render = { :layout => false, :template => '' }
  
  def render(template)
    $frucnatra_render[:layout] = true if File.exist? "#{$frucnatra_dir}/views/layout.php"
    $frucnatra_render[:template] = template
  end
  
  def views_workaround(file)
    if ($frucnatra_render[:layout] and file == 'layout') or File.exist? "#{$frucnatra_dir}/views/#{file}.php"
      _php_include "views/#{file}.php"
    end
  end
  
  $frucnatra_session = false
  
  def enable(opt) #(*opts)
    if opt == :sessions
      $frucnatra_session = true
    end
  end
  
  def disable(opt) #(*opts)
    if opt == :sessions
      if $frucnatra_session
        $frucnatra_session = false
      end
    end
  end
  
  def frucnatra_shutdown
    path_info = $server[:PATH_INFO] || '/'
    method = $server[:REQUEST_METHOD]
    
    # Public files take precendence
    if path_info != '/'
      pub_test = phpcall :realpath, "#{$frucnatra_dir}/public#{path_info}"
      if pub_test.is_a? :String and pub_test.gsub("#{$frucnatra_dir}", '')[1,6] == 'public'
        redirect "#{$root}/public#{path_info}"
        return
      end
    end
    
    if routes = $routes[method]
      routes.each do |arr| # Splatting to block params not supported yet
        pattern, keys, conditions, block = arr

        if match = pattern.match(path_info)
          values = match.captures.to_a
          params =
            if keys.any?
              keys.zip(values).reduce({}) do |hash,a| #keys.zip(values).inject({}) do |hash,(k,v)|
                k,v = a
                if k == 'splat'
                  (hash[k.to_sym] ||= []) << v
                else
                  hash[k.to_sym] = v
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
          
          # Session var
          if $frucnatra_session
            define_global_method :session do
              $session
            end
          end
          
          result = block.call
          
          if $frucnatra_render[:layout]
            views_workaround 'layout' do
              phpcall :ob_start
              views_workaround $frucnatra_render[:template]
              buffer = phpcall :ob_get_contents
              phpcall :ob_end_clean
              buffer
            end
          else
            puts result
          end
          
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
  
  $frucnatra_statustext = {
    100=>'100 Continue',
    101=>'101 Switching Protocols',
    # [Successful 2xx]  
    200=>'200 OK',
    201=>'201 Created',
    202=>'202 Accepted',
    203=>'203 Non-Authoritative Information',
    204=>'204 No Content',
    205=>'205 Reset Content',
    206=>'206 Partial Content',
    # [Redirection 3xx]  
    300=>'300 Multiple Choices',
    301=>'301 Moved Permanently',
    302=>'302 Found',
    303=>'303 See Other',
    304=>'304 Not Modified',
    305=>'305 Use Proxy',
    306=>'306 (Unused)',
    307=>'307 Temporary Redirect',
    # [Client Error 4xx]  
    400=>'400 Bad Request',
    401=>'401 Unauthorized',
    402=>'402 Payment Required',
    403=>'403 Forbidden',
    404=>'404 Not Found',
    405=>'405 Method Not Allowed',
    406=>'406 Not Acceptable',
    407=>'407 Proxy Authentication Required',
    408=>'408 Request Timeout',
    409=>'409 Conflict',
    410=>'410 Gone',
    411=>'411 Length Required',
    412=>'412 Precondition Failed',
    413=>'413 Request Entity Too Large',
    414=>'414 Request-URI Too Long',
    415=>'415 Unsupported Media Type',
    416=>'416 Requested Range Not Satisfiable',
    417=>'417 Expectation Failed',
    418=>'418 I\'m a teapot',
    # [Server Error 5xx]  
    500=>'500 Internal Server Error',
    501=>'501 Not Implemented',
    502=>'502 Bad Gateway',
    503=>'503 Service Unavailable',
    504=>'504 Gateway Timeout',
    505=>'505 HTTP Version Not Supported' 
  }
#end