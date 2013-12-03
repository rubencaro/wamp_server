require 'rubygems'
require 'bundler/setup'
require 'em-synchrony'
require 'json'
$:.unshift File.expand_path('lib')
require 'wamp'
require 'wamp_server'
require 'app'
require 'log_helpers'

EM.synchrony do
  host = '0.0.0.0'
  port = '3000'

  trap("INT") { WampServer.stop }
  trap("TERM") { WampServer.stop }
  trap("KILL") { WampServer.stop }

  App.init

  H.log "Listening on #{host}:#{port}", :clean => true
  WampServer.start(:host => host, :port => port) do |ws|

    ws.onopen do
      Fiber.new do
        ws.send WampServer.welcome(ws)
      end.resume
    end

    ws.onmessage do |msg, type|
      H.log "Received message: #{msg}"
      Fiber.new do
        begin
          call = JSON.parse msg
        rescue JSON::ParserError
          ws.send( WampServer::RESPONSES[:not_json] )
        end

        if call.first == WAMP::PREFIX then
          App.save_prefix ws, call
        elsif call.first == WAMP::CALL then
          #[ TYPE_ID_CALL , callID , procURI , ... ]
          uri = App.solve_uri ws, call[2]
          controller, action = App.parse_uri uri
          begin
            result = App.route(controller, action, *call[3..-1])
            ws.send [WAMP::CALLRESULT, call[1], result].to_json
          rescue => ex
            H.log_ex ex
            ws.send [WAMP::CALLERROR, call[1], "http://#{controller}#error", ex.to_s].to_json
          end
        else # pubsub
          H.spit "route: #{call}"
        end
      end.resume
    end

    ws.onclose do
      Fiber.new do
        ws.send App.remove_session(ws)
      end.resume
    end

  end

end
