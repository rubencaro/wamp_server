require 'websocket-eventmachine-server'
require 'json'
require_relative 'version'

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
    a_module.extend a_module

    host = opts[:host] || '0.0.0.0'
    port = opts[:port] || '3000'

    EM.run do

      trap("INT") { WAMP.stop_server }
      trap("TERM") { WAMP.stop_server }
      trap("KILL") { WAMP.stop_server }

      a_module.before_start if a_module.respond_to?(:before_start)

      puts "Listening on #{host}:#{port}"
      WebSocket::EventMachine::Server.start(:host => host, :port => port) do |ws|

        ws.onopen do
          onopen ws, a_module
        end

        ws.onmessage do |msg, type|
          onmessage ws, msg, a_module
        end

        ws.onclose do
          onclose ws, a_module
        end

      end # Server.start
    end # EM.run

  end

  def self.onopen(ws, a_module)
    Fiber.new do
      sid = a_module.onwelcome ws: ws
      ws.send [WAMP::WELCOME, sid, 1, WAMP.stamp].to_json
    end.resume
  end

  def self.onclose(ws, a_module)
    Fiber.new do
      a_module.onclose ws: ws
    end.resume
  end

  def self.onmessage(ws, msg, a_module)
    Fiber.new do
      begin
        call = JSON.parse msg
      rescue JSON::ParserError
        ws.send( WAMP::RESPONSES[:not_json] )
      end

      if call.first == WAMP::CALL then
        oncall ws, call, a_module
      elsif call.first == WAMP::PUBLISH then
        onpublish ws, call, a_module
      elsif call.first == WAMP::SUBSCRIBE then
        # [ TYPE_ID_SUBSCRIBE , topicURI ]
        a_module.onsubscribe ws: ws, curie: call[1]
      elsif call.first == WAMP::UNSUBSCRIBE then
        # [ TYPE_ID_UNSUBSCRIBE , topicURI ]
        a_module.onunsubscribe ws: ws, curie: call[1]
      elsif call.first == WAMP::PREFIX then
        # [ TYPE_ID_PREFIX , prefix, URI ]
        _, prefix, uri = call
        a_module.onprefix ws: ws, uri: uri, prefix: prefix
      end
    end.resume
  end

  def self.oncall(ws, call, a_module)
    # [ TYPE_ID_CALL , callID , procURI , ... ]
    _, callid, curie, *args = call
    result = a_module.oncall ws: ws, curie: curie, args: args
    ws.send [WAMP::CALLRESULT, callid, result].to_json
  rescue => ex
    ws.send [WAMP::CALLERROR, callid, "http://error", ex.to_s].to_json
  end

  def self.onpublish(ws, call, a_module)
    # [ TYPE_ID_PUBLISH , topicURI , event , exclude , eligible ]
    _, curie, event, excluded, eligible = call
    result = a_module.onpublish curie: curie
    dest = (result[:subscribed] & eligible) - excluded
    package = [WAMP::EVENT, result[:uri], event].to_json
    dest.each do |d|
      ObjectSpace._id2ref(d).send( package )
    end
  end

end
