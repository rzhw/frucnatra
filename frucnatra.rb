require 'http'
require 'phpcall'

class Frucnatra
end

class FrucnatraRequest
  def path_info
    # PATH_INFO isn't guaranteed to be set. Also, on some servers, it may be ORIG_PATH_INFO instead.
    $server[:PATH_INFO].untaint || $server[:ORIG_PATH_INFO].untaint || '/'
  end
end
$frucnatra_request = FrucnatraRequest.new
define_global_method :request do
  $frucnatra_request
end

#module Frucnatra
  # Methods available to routes, before/after filters, and views.
  #module Helpers
    def status(value)
      phpcall :header, "HTTP/1.1 #{frucnatra_http_statuses[value]}"
    end
    
    def redirect(uri)
      status 302
      phpcall :header, "Location: #{uri}"
      halt
    end
  #end
  
  $frucnatra_routes = Hash.new do |h,k|
    h[k] = []
  end
  
  # Frucnatra isn't a DSL, so this is needed
  request_uri_decoded = phpcall :urldecode, $server[:REQUEST_URI]
  $frucnatra_root = request_uri_decoded[0, request_uri_decoded.length - request.path_info.length]
  define_global_method :url_root do
    $frucnatra_root
  end
  
  def halt
    `exit();`
  end

  def get(path, opts={}, &block)
    route 'GET', path, opts, &block
  end

  def put(path, opts={}, &bk)     route 'PUT',     path, opts, &bk end
  def post(path, opts={}, &bk)    route 'POST',    path, opts, &bk end
  def delete(path, opts={}, &bk)  route 'DELETE',  path, opts, &bk end
  def head(path, opts={}, &bk)    route 'HEAD',    path, opts, &bk end
  def options(path, opts={}, &bk) route 'OPTIONS', path, opts, &bk end

  def route(verb, path, options={}, &block)
    dummy_block, pattern, keys, conditions = compile! verb, path, nil, options
    
    #($routes[verb] ||= []).
    #  push([pattern, keys, conditions, block]).last
    
    $frucnatra_routes[verb][$frucnatra_routes[verb].count] = [pattern, keys, conditions, Proc.new(&block)] # Using Proc.new as a temp Fructose-related thing
  end
  
  def compile!(verb, path, block, options={})
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
  $frucnatra_already_rendered_layout = false # I'm not sure if Sinatra does this as well
  
  def erb(template) render template end
  
  def render(template)
    f = Proc.new {|template|
      if not template.is_a? :String
        phpcall :ob_start
        views_workaround template
        buffer = phpcall :ob_get_contents
        phpcall :ob_end_clean
        buffer
      else
        template
      end
    }
    
    if File.exist? "#{$frucnatra_dir}/views/layout.php" and not $frucnatra_already_rendered_layout
      views_workaround :layout do
        $frucnatra_already_rendered_layout = true
        f.call template
      end
    else
      f.call template
    end
  end
  
  def views_workaround(file)
    if File.exist? "#{$frucnatra_dir}/views/#{file}.php"
      _php_include "views/#{file}.php"
    end
  end
  
  $frucnatra_session = false
  
  def set(option, value)
    case option
      when :sessions
        $frucnatra_session = value
    end
  end

  # Same as calling `set :option, true` for each of the given options.
  def enable(*opts)
    opts.each { |key| set(key, true) }
  end

  # Same as calling `set :option, false` for each of the given options.
  def disable(*opts)
    opts.each { |key| set(key, false) }
  end
  
  # Params
  $frucnatra_params = {}
  $request.each do |k,v|
    $frucnatra_params = $frucnatra_params.merge({ k => v.untaint })
  end

  # Workaround for NodeType SelfReference not supported yet (in the compile! method)
  define_global_method :params do
    $frucnatra_params
  end
  
  # Session
  define_global_method :session do
    $session if $frucnatra_session
    [] unless $frucnatra_session
  end
  
  def frucnatra_shutdown
    path_info = request.path_info
    method = $server[:REQUEST_METHOD]
    
    # Public files take precendence
    if path_info != '/'
      pub_test = phpcall :realpath, "#{$frucnatra_dir}/public#{path_info}"
      if pub_test.is_a? :String and pub_test.gsub("#{$frucnatra_dir}", '')[1,6] == 'public'
        redirect "#{$frucnatra_root}/public#{path_info}"
        return
      end
    end
    
    if routes = $frucnatra_routes[method]
      routes.each do |arr| # Splatting to block params not supported yet
        pattern, keys, conditions, block = arr

        if match = pattern.match(path_info)
          values = match.captures.to_a
          params2 =
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
          
          # Params
          $frucnatra_params = $frucnatra_params.merge params2
          
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
  
  def frucnatra_http_statuses
    {
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
  end
#end