require 'websocket-eventmachine-server'
require 'json'
require 'em-synchrony'

#
# see http://wamp.ws/spec
#
module WAMP

  VERSION = '0.1'

  WELCOME = 0
  PREFIX = 1
  CALL = 2
  CALLRESULT = 3
  CALLERROR = 4
  SUBSCRIBE = 5
  UNSUBSCRIBE = 6
  PUBLISH = 7
  EVENT = 8

  RESPONSES = { :not_json => { :error => 'Message is not JSON !' }.to_json }

  def self.stamp
    "#{self.name} #{VERSION}"
  end

  def self.stop_server
    puts "Terminating WebSocket Server"
    EM.stop
  end

  # Start a new Server
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
  def self.start_server(a_module, opts = {})

    # avoid more instances
    a = a_module
    a.extend a

    host = opts[:host] || '0.0.0.0'
    port = opts[:port] || '3000'

    EM.run do

      trap("INT") { WAMP.stop_server }
      trap("TERM") { WAMP.stop_server }
      trap("KILL") { WAMP.stop_server }

      a.before_start if a.respond_to?(:before_start)

      puts "Listening on #{host}:#{port}"
      WebSocket::EventMachine::Server.start(:host => host, :port => port) do |ws|

        ws.onopen do
          Fiber.new do
            sid = a.onwelcome ws: ws
            ws.send [WAMP::WELCOME, sid, 1, WAMP.stamp].to_json
          end.resume
        end

        ws.onmessage do |msg, type|
          Fiber.new do
            begin
              call = JSON.parse msg
            rescue JSON::ParserError
              ws.send( WAMP::RESPONSES[:not_json] )
            end

            if call.first == WAMP::CALL then
              # [ TYPE_ID_CALL , callID , procURI , ... ]
              _, callid, curie, *args = call
              begin
                result = a.oncall ws: ws, curie: curie, args: args
                ws.send [WAMP::CALLRESULT, callid, result].to_json
              rescue => ex
                ws.send [WAMP::CALLERROR, callid, "http://error", ex.to_s].to_json
              end
            elsif call.first == WAMP::PUBLISH then
              # [ TYPE_ID_PUBLISH , topicURI , event , exclude , eligible ]
              _, curie, event, excluded, eligible = call
              result = a.onpublish curie: curie
              dest = (result[:subscribed] & eligible) - excluded
              package = [WAMP::EVENT, result[:uri], event].to_json
              dest.each do |d|
                ObjectSpace._id2ref(d).send( package )
              end
            elsif call.first == WAMP::SUBSCRIBE then
              # [ TYPE_ID_SUBSCRIBE , topicURI ]
              a.onsubscribe ws: ws, curie: call[1]
            elsif call.first == WAMP::UNSUBSCRIBE then
              # [ TYPE_ID_UNSUBSCRIBE , topicURI ]
              a.onunsubscribe ws: ws, curie: call[1]
            elsif call.first == WAMP::PREFIX then
              # [ TYPE_ID_PREFIX , prefix, URI ]
              _, prefix, uri = call
              a.onprefix ws: ws, uri: uri, prefix: prefix
            end
          end.resume
        end

        ws.onclose do
          Fiber.new do
            a.onclose ws: ws
          end.resume
        end

      end # Server.start
    end # EM.synchrony

  end

end
