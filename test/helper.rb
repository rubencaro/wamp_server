require 'minitest/pride'
require 'minitest/autorun'
require 'websocket-eventmachine-client'
require 'pty'
require 'socket'

def force_constant(klass, name, value)
  previous_value = klass.send(:remove_const, name)
  klass.const_set name.to_s, value
  previous_value
end

def run_ws_client(cb_onopen, cb_onmessage, cb_onclose, opts = {})
  timeout = opts[:timeout] || 5
  EM.run do
    ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://0.0.0.0:3000')
    ws.onopen{ cb_onopen.call(ws) }
    ws.onmessage{ |msg, type| cb_onmessage.call(ws,msg,type) }
    ws.onclose { cb_onclose.call(ws) }
  end
end

##
# Start a server before running tests and cleanup afterwards

SERVER_CMD="ruby main.rb"

def clean_test_stuff
  `pkill -f '#{SERVER_CMD}'`
end

def is_online?
  s = TCPSocket.new 'localhost', 3000
  s.close
  true
rescue Errno::ECONNREFUSED
  false
end

def wait_for_server_to_be_online
  print "Waiting for server to be online..."
  while not is_online? do
    print '.'
    sleep 0.2
  end
  puts '.'
end

Minitest.after_run{ clean_test_stuff }
trap("INT") { clean_test_stuff; exit 0 }

clean_test_stuff # just in case

Thread.new do
  begin
    PTY.spawn( "bundle exec " + SERVER_CMD + " 2>&1" ) do |stdin, stdout, pid|
      begin; stdin.each { |line| print line }; rescue Errno::EIO; end
    end
  rescue PTY::ChildExited; puts "The child process exited!";  end
end

wait_for_server_to_be_online
