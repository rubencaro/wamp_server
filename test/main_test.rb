require_relative 'helper'
require 'wamp'

class TestMain < Minitest::Test

  def test_plain_ws
    cb = lambda do |ws,msg,type,info|
      ws.close
    end
    info = run_ws_client onmessage: cb
    assert_equal 1, info[:messages].count
  end

  def test_welcome
    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg
      # [ TYPE_ID_WELCOME , sessionId , protocolVersion, serverIdent ]
      assert_equal 4, data.count
      assert_equal WAMP::WELCOME, data[0]
      assert_equal 1, data[2] # protocol version
      ws.close
    end
    info = run_ws_client onmessage: cb
    assert_equal 1, info[:messages].count
  end

  def test_call

  end

end
