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
      H.spit 'welcome'
      ws.send ['hola'].to_json
#      Fiber.new do
#        ws.send WampServer.welcome(ws)
#      end.resume
    end

    ws.onmessage do |msg, type|
      H.spit msg
      H.log "Received message: #{msg}"
#      Fiber.new do
#        begin
#          call = JSON.parse msg
#        rescue JSON::ParserError
#          ws.send( WampServer::RESPONSES[:not_json] )
#        else
#          if call.first == WAMP::PREFIX then
#            App.save_prefix ws, call
#          else # rpc or pubsub
#            App.route ws,call
#          end
#        end
#      end.resume
    end

    ws.onclose do
            H.spit 'close'
#      Fiber.new do
#        ws.send App.remove_session(ws)
#      end.resume
    end

  end

end
