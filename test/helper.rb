require 'minitest/pride'
require 'minitest/autorun'
require 'websocket-eventmachine-client'
require 'pty'
require 'socket'
require 'timeout'

def force_constant(klass, name, value)
  previous_value = klass.send(:remove_const, name)
  klass.const_set name.to_s, value
  previous_value
end

def run_ws_client(opts = {})

  cb_onopen = opts[:onopen] || lambda{ |ws,info| }
  cb_onmessage = opts[:onmessage] || lambda{ |ws,msg,type,info| ws.close } # remember to close ws !
  cb_onclose = opts[:onclose] || lambda{ |ws,info| }

  info = {} # hash to gather info
  connection_timeout = opts[:connection_timeout] || 1 # timeout until onopen
  message_timeout = opts[:message_timeout] || 3       # timeout between messages
  EM.run do

    timer = EM::Timer.new(connection_timeout){ raise Timeout::Error.new "Waited #{connection_timeout} seconds !" }
    ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://0.0.0.0:3000')

    ws.onopen do
      timer.cancel
      cb_onopen.call(ws,info)
      timer = EM::Timer.new(message_timeout){ raise Timeout::Error.new "Waited #{message_timeout} seconds !" }
    end

    ws.onmessage do |msg, type|
      timer.cancel
      info[:messages] ||= []
      info[:messages] << msg
      cb_onmessage.call(ws,msg,type,info)
      timer = EM::Timer.new(message_timeout){ raise Timeout::Error.new "Waited #{message_timeout} seconds !" }
    end

    ws.onclose do
      timer.cancel
      cb_onclose.call(ws,info)
      EM.stop
    end
  end
  info
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
