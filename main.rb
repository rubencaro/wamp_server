require 'fiber_connection_pool'
require 'mongo'
require 'em-synchrony'
require 'mongo-em-patch'
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

  WampServer.db = FiberConnectionPool.new(:size => 5) do
                    Mongo::Connection.new.db('bogusdb')
                  end

  H.log "Listening on #{host}:#{port}", :clean => true
  WampServer.start(:host => host, :port => port) do |ws|

    ws.onopen do
      ws.send WampServer.welcome
    end

    ws.onmessage do |msg, type|
      H.log "Received message: #{msg}"
      Fiber.new do
        begin
          call = JSON.parse msg
        rescue JSON::ParserError
          ws.send( WampServer::RESPONSES[:not_json] )
        else
          AppLogic.route ws,call
        end
      end.resume
    end

    ws.onclose do
    end

  end

end
