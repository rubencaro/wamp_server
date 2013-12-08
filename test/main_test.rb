require_relative 'helper'
require 'wamp'
require 'em-synchrony'

class TestMain < Minitest::Test

  def test_plain_ws
    H.announce
    cb = lambda do |ws,msg,type,info|
      ws.close
    end
    info = run_ws_client onmessage: cb
    assert_equal 1, info[:messages].count
  end

  def test_welcome
    H.announce
    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg
      check_is_welcome data
      result = call(ws,'get_db','sessions')
      assert_equal 1, result.count, "#{result}"
      ws.close
    end
    info = run_ws_client onmessage: cb
    assert_equal 1, info[:messages].count, info
  end

  def test_prefix
    H.announce
    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg

      assert_equal WAMP::WELCOME, data.first, "#{data}"

      uri = "http://test#"
      prefix = 'test'

      ws.send [WAMP::PREFIX, prefix, uri].to_json
      result = call(ws,'get_db','sessions')
      assert_equal 1, result.count, result
      assert_equal uri, result.first['prefixes'][prefix], "#{result}"
      ws.close
    end
    info = run_ws_client onmessage: cb
    assert_equal 1, info[:messages].count, info
  end

  def test_rpc
  end

  def test_pubsub
  end

  private

  def check_is_welcome(data)
    # [ TYPE_ID_WELCOME , sessionId , protocolVersion, serverIdent ]
    assert_equal 4, data.count
    assert_equal WAMP::WELCOME, data[0]
    assert_equal 1, data[2] # protocol version
  end

end
