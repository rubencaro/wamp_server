require 'websocket-eventmachine-server'
require 'json'
require 'log_helpers'
require 'em-synchrony'

#
# see http://wamp.ws/spec
#
module WAMP

  WELCOME = 0
  PREFIX = 1
  CALL = 2
  CALLRESULT = 3
  CALLERROR = 4
  SUBSCRIBE = 5
  UNSUBSCRIBE = 6
  PUBLISH = 7
  EVENT = 8

  class Server < WebSocket::EventMachine::Server
    VERSION = '0.1'

    RESPONSES = { :not_json => { :error => 'Message is not JSON !' }.to_json }

    def self.stamp
      "#{self.name} #{VERSION}"
    end

    def self.welcome(ws)
      App.init_session(ws)
      H.log "Welcome #{ws.object_id}"
      [WAMP::WELCOME, ws.object_id, 1, WAMP::Server.stamp].to_json
    end

    def self.stop
      H.log "Terminating WebSocket Server"
      EM.stop
    end
  end

  # Start a new WAMP::Server
  #
  # You should pass some callbacks:
  #
  #   :before_start => To be called before actually starting the server, but already within EM reactor.
  #   :onwelcome => To be called for WELCOME calls.
  #   :onprefix => To be called for PREFIX calls.
  #   :oncall => To be called when server receives a CALL call.
  #   :onpublish => To be called when server receives a PUBLISH call.
  #   :onclose => To be called when a client closes connection.
  #   :onsubscribe => Called for SUBSCRIBE calls.
  #   :onunsubscribe => On UNSUBSCRIBE calls.
  #
  def self.start_server(opts)
    host = opts[:host] || '0.0.0.0'
    port = opts[:port] || '3000'

    EM.synchrony do

      trap("INT") { WAMP::Server.stop }
      trap("TERM") { WAMP::Server.stop }
      trap("KILL") { WAMP::Server.stop }

      opts[:before_start].call if opts[:before_start].respond_to?(:call)

      H.log "Listening on #{host}:#{port}", :clean => true
      WAMP::Server.start(:host => host, :port => port) do |ws|

        ws.onopen do
          Fiber.new do
            sid = opts[:onwelcome].call ws: ws
            ws.send [WAMP::WELCOME, sid, 1, WAMP::Server.stamp].to_json
          end.resume
        end

        ws.onmessage do |msg, type|
          H.log "Received message: #{msg}"
          Fiber.new do
            begin
              call = JSON.parse msg
            rescue JSON::ParserError
              ws.send( WAMP::Server::RESPONSES[:not_json] )
            end

            if call.first == WAMP::CALL then
              # [ TYPE_ID_CALL , callID , procURI , ... ]
              _, callid, curie, *args = call
              begin
                result = opts[:oncall].call ws: ws, curie: curie, args: args
                ws.send [WAMP::CALLRESULT, callid, result].to_json
              rescue => ex
                H.log_ex ex
                ws.send [WAMP::CALLERROR, callid, "http://error", ex.to_s].to_json
              end
            elsif call.first == WAMP::PUBLISH then
              # [ TYPE_ID_PUBLISH , topicURI , event , exclude , eligible ]
              _, curie, event, excluded, eligible = call
              result = opts[:onpublish].call curie: curie
              dest = (result[:subscribed] & eligible) - excluded
              package = [WAMP::EVENT, result[:uri], event].to_json
              dest.each do |d|
                ObjectSpace._id2ref(d).send( package )
              end
            elsif call.first == WAMP::SUBSCRIBE then
              # [ TYPE_ID_SUBSCRIBE , topicURI ]
              opts[:onsubscribe].call ws: ws, curie: call[1]
            elsif call.first == WAMP::UNSUBSCRIBE then
              # [ TYPE_ID_UNSUBSCRIBE , topicURI ]
              opts[:onunsubscribe].call ws: ws, curie: call[1]
            elsif call.first == WAMP::PREFIX then
              # [ TYPE_ID_PREFIX , prefix, URI ]
              _, prefix, uri = call
              opts[:onprefix].call ws: ws, uri: uri, prefix: prefix
            end
          end.resume
        end

        ws.onclose do
          Fiber.new do
            opts[:onclose].call ws: ws
          end.resume
        end

      end # WAMP::Server.start
    end # EM.synchrony

  end

end
