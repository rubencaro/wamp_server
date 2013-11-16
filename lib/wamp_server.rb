require 'websocket-eventmachine-server'
require 'json'
require 'wamp'

class WampServer < WebSocket::EventMachine::Server
  VERSION = '0.1'

  RESPONSES = { :not_json => { :error => 'Message is not JSON !' }.to_json }

  def self.db=(value); @@db = value; end
  def self.db; @@db; end

  def self.stamp
    "#{self.name} #{VERSION}"
  end

  def self.welcome
    [WAMP::WELCOME, WAMP.new_session_id, 1, WampServer.stamp].to_json
  end

  def self.stop
    puts "Terminating WebSocket Server"
    EM.stop
  end
end
