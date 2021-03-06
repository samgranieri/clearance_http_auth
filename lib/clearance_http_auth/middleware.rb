module Clearance
  module HttpAuth

    # A Rack middleware which intercepts requests to your application API
    # (as defined in <tt>Configuration.api_formats</tt>) and performs
    # a HTTP Basic Authentication via <tt>Rack::Auth::Basic</tt>.
    #
    class Middleware

      def initialize(app)
        @app = app
      end

      # Wrap the application with a <tt>Rack::Auth::Basic</tt> block
      # and set the <tt>env['clearance.current_user']</tt> variable
      # if the incoming request is targeting the API.
      #
      def call(env)
        if targeting_api?(env) and (env['HTTP_AUTHORIZATION'] or Configuration.bypass_auth_without_credentials == false)
          if env['HTTP_ACCEPT'].nil?
            env['HTTP_ACCEPT'] = '*/*'
          end
          @app = Rack::Auth::Basic.new(@app) do |username, password|
            env[:clearance].sign_in ::User.authenticate(username, password)
          end
        end
        @app.call(env)
      end

      private

      def targeting_api?(env)
        if env['action_dispatch.request.path_parameters']
          format = env['action_dispatch.request.path_parameters'][:format]
          return true if format && Configuration.api_formats.include?(format)
        end
        if Configuration.http_accept_matching
          return true if Configuration.api_formats.any?{|format| env['HTTP_ACCEPT'] =~ /application\/#{format}/i}
        end
        if Configuration.content_type_matching
          return true if Configuration.api_formats.any?{|format| env['CONTENT_TYPE'] =~ /application\/#{format}/i}
        end
        return false
      end

    end

  end

end
