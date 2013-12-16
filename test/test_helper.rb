require 'minitest/pride'
require 'minitest/autorun'
require 'websocket-eventmachine-client'
require 'pty'
require 'socket'
require 'timeout'
require 'json'
require 'em-synchrony'

require_relative 'log_helpers'

class TestCase < Minitest::Test

  # hijack a satellite client to be the main client
  def run_ws_client(opts = {})

    info = {} # hash to gather info

    prev_onclose = opts[:onclose]
    opts[:onclose] = lambda do |ws,info|
      prev_onclose.call(ws,info) if prev_onclose
      EM.stop # stop after this client closes
    end

    EM.run do
      run_satellite_ws_client info, opts
    end
    info
  end

  # run a WebSocket::EventMachine::Client assuming to be a satellite client,
  # i.e. inside an EM.run loop and not stopping it
  def run_satellite_ws_client(info, opts = {})

    opts[:onopen] ||= lambda{ |ws,info| }
    opts[:onmessage] ||= lambda{ |ws,msg,type,info| ws.close } # remember to close ws !
    opts[:onclose] ||= lambda{ |ws,info| }

    connection_timeout = opts[:connection_timeout] || 1 # timeout until onopen
    message_timeout = opts[:message_timeout] || 5       # timeout between messages

    timer = EM::Timer.new(connection_timeout){ raise Timeout::Error.new "Waited #{connection_timeout} seconds !" }
    ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://0.0.0.0:3000')

    ws.onopen do
      timer.cancel
      Fiber.new do opts[:onopen].call(ws,info) end.resume
      timer = EM::Timer.new(message_timeout){ raise Timeout::Error.new "Waited #{message_timeout} seconds !" }
    end

    ws.onmessage do |msg, type|
      timer.cancel
      info[:messages] ||= []
      info[:messages] << JSON.parse(msg)
      Fiber.new do opts[:onmessage].call(ws,msg,type,info) end.resume
      timer = EM::Timer.new(message_timeout){ raise Timeout::Error.new "Waited #{message_timeout} seconds !" }
    end

    ws.onclose do
      timer.cancel
      Fiber.new do opts[:onclose].call(ws,info) end.resume
    end
  end

  def wait_for(timeout = 3)
    loc = caller_locations(1,1)[0]
    place = loc.path + ":" + loc.lineno.to_s
    timer = EM::Timer.new(timeout){ assert false, "Waited #{timeout} seconds on #{place}" }
    while(!yield) do EM::Synchrony.sleep(0.1) end
    timer.cancel
  end

  def check_is_json(txt)
    begin
      data = JSON.parse(txt)
    rescue => err
      H.log_ex err, msg: "Is not JSON: #{txt}"
    end
    assert !data.nil?, msg: "Is not JSON: #{txt}"
    data
  end

  # make a call to test controller from within the same client
  # assumes no one is making any calls while it's acting
  #
  def call(ws, action, *args)
    cmd = [WAMP::CALL, 'id', "http://test##{action}"] + args
    result = nil

    # save current callback
    prev_onmessage = ws.instance_variable_get(:@onmessage)

    calling_fiber = Fiber.current

    # put in place a temp callback to get the result
    new_onmessage = Proc.new do |msg, type|
      data = check_is_json msg
      result = data.last
      calling_fiber.resume
    end
    ws.instance_variable_set(:@onmessage, new_onmessage)

    # make the call
    ws.send cmd.to_json

    # yield until the callback resumes this fiber
    Fiber.yield

    # return the original callback
    ws.instance_variable_set(:@onmessage, prev_onmessage)

    result
  end

  # make a request to test controller running a new ws_client
  def request(action, *args)
    cmd = [WAMP::CALL, 'id', "http://test##{action}"] + args
    result = nil
    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg
      if data.first == WAMP::WELCOME then
        ws.send cmd.to_json
      else # CALLRESULT or CALLERROR
        result = data.last
        ws.close
      end
    end
    run_ws_client onmessage: cb
    result
  end

  def assert(boolean, message=nil)
    message = message.call if message.respond_to?(:call)
    message = H.yellow(message.to_s) + H.brown("\n#{caller}")
    super(boolean, message)
  end

  def todo(msg = nil, opts = {})
    label = caller_locations(1,1)[0].label
    place = File.basename(caller_locations(1,1)[0].path) + ":" + caller_locations(1,1)[0].lineno.to_s
    msg ||= "\n TODO: #{label} (#{place})..."
    opts[:color] ||= :yellow
    opts[:clean] = true
    H.log msg, opts
    skip msg
  end

end

##
# Start a server before running tests and cleanup afterwards

SERVER_CMD="ruby test/test_app/main.rb"

def is_online?
  s = TCPSocket.new 'localhost', 3000
  s.close
  true
rescue Errno::ECONNREFUSED, Errno::ECONNRESET
  false
end

def wait_for_server_to_be_online(timeout = 5)
  print "Waiting for server to be online..."
  t = Time.now
  while not is_online? do
    print '.'
    raise Timeout::Error.new "Waited #{timeout} seconds !" if Time.now - t > timeout
    sleep 0.2
  end
end

def wait_for_server_to_be_offline(timeout = 5)
  print "Ensuring server is offline..."
  t = Time.now
  while is_online? do
    print '.'
    raise Timeout::Error.new "Waited #{timeout} seconds !" if Time.now - t > timeout
    sleep 0.2
  end
  puts 'ok'
end

def clean_test_stuff
  `pkill -f '#{SERVER_CMD}'`
  wait_for_server_to_be_offline
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
