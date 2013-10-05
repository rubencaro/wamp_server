require 'websocket-eventmachine-server'
require 'fiber_connection_pool'
require 'mongo'
require 'em-synchrony'
require 'mongo-em-patch'
require 'fiber'
require 'json'
$:.unshift File.expand_path('lib')
require 'wamp'

module AppLogic
  def self.do_things
    res = MyServer.pool.collection('bogus').find( :$where => "sleep(2000)" ).count
    "Done #{Thread.current.to_s}, #{Fiber.current.to_s} res:#{res.inspect}"
  end
end

class MyServer < WebSocket::EventMachine::Server
  VERSION='0.1'

  def self.pool=(value); @@pool = value; end
  def self.pool; @@pool; end

  def self.stamp
    "#{self.name} #{VERSION}"
  end

  def self.stop
    puts "Terminating WebSocket Server"
    EM.stop
  end
end

EM.synchrony do
  host = '0.0.0.0'
  port = '3000'

  trap("INT") { MyServer.stop }

  MyServer.pool = FiberConnectionPool.new(:size => 5) do
                    Mongo::Connection.new.db('bogusdb')
                  end

  puts "Listening on #{host}:#{port}..."
  MyServer.start(:host => host, :port => port) do |ws|

    ws.onopen do
      ws.send [WAMP::WELCOME, WAMP.new_session_id, 1, MyServer.stamp].to_json
    end

    ws.onmessage do |msg, type|
      puts "Received message: #{msg}"
      Fiber.new do
        begin
          call = JSON.parse msg
        rescue JSON::ParserError
          ws.send( { :error => 'Message is not JSON !' }.to_json )
        else
          AppLogic.route ws,call
        end
      end.resume
    end

    ws.onclose do
    end

  end

end
