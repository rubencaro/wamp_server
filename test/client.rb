require 'websocket-eventmachine-client'
require 'pry-remote-em/server'


EM.run do

  ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://localhost:3000')

  ws.onopen do
    puts "Connected"
  end

  ws.onmessage do |msg, type|
    puts "Received message: #{msg}"
  end

  ws.onclose do
    puts "Disconnected"
  end

  binding.remote_pry_em

end
