require 'websocket-eventmachine-server'
require 'json'
require 'wamp'
require 'log_helpers'

class WampServer < WebSocket::EventMachine::Server
  VERSION = '0.1'

  RESPONSES = { :not_json => { :error => 'Message is not JSON !' }.to_json }

  def self.db=(value); @@db = value; end
  def self.db; @@db; end

  def self.stamp
    "#{self.name} #{VERSION}"
  end

  def self.welcome(ws)
    App.init_session(ws)
    H.log "Welcome #{ws.object_id}"
    [WAMP::WELCOME, ws.object_id, 1, WampServer.stamp].to_json
  end

  def self.stop
    H.log "Terminating WebSocket Server"
    App.clear_sessions
    EM.stop
  end
end
