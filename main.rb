require 'websocket-eventmachine-server'
require 'fiber_connection_pool'
require 'mongo'
require 'em-synchrony'
require 'mongo-em-patch'
require 'fiber'

module AppLogic
  def self.do_things
    res = MyServer.pool.collection('bogus').find( :$where => "sleep(2000)" ).count
    "Done #{Thread.current.to_s}, #{Fiber.current.to_s} res:#{res.inspect}"
  end
end

class MyServer < WebSocket::EventMachine::Server
  def self.pool=(value); @@pool = value; end
  def self.pool; @@pool; end

  def self.stop
    puts "Terminating WebSocket Server"
    EventMachine.stop
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
      puts "Client connected"
      ws.send 'hi fella'
    end

    ws.onmessage do |msg, type|
      t1 = Time.now
      puts "Received message: #{msg}"
      Fiber.new do
        res = AppLogic.do_things
        ws.send res.to_s + " Took #{Time.now - t1} secs" , :type => type
      end.resume
    end

    ws.onclose do
      puts "Client disconnected"
    end

  end

end
