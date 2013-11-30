require_relative 'helper'
require 'wamp'
require 'em-synchrony'

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

      assert [WAMP::WELCOME,WAMP::CALLRESULT].include?(data.first), "#{data}"

      if data.first == WAMP::WELCOME then
        check_is_welcome data
        ws.send [WAMP::CALL, 'id', "http://testing#get_db"].to_json
      else # CALLRESULT
        result = data.last
        assert_equal 1, result['sessions'].count, "#{result}"
        ws.close
      end
    end
    info = run_ws_client onmessage: cb
    assert_equal 2, info[:messages].count, info
  end

  def test_prefix
    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg

      assert [WAMP::WELCOME,WAMP::CALLRESULT].include?(data.first), "#{data}"

      uri = "http://testing#"
      prefix = 'test'

      if data.first == WAMP::WELCOME then
        ws.send [WAMP::PREFIX, prefix, uri].to_json
        ws.send [WAMP::CALL, 'id', "#{prefix}:get_db"].to_json
      else # CALLRESULT
        result = data.last
        assert_equal uri, result['sessions'].values.first['prefixes'][prefix], "#{result}"
        ws.close
      end
    end
    info = run_ws_client onmessage: cb
    assert_equal 2, info[:messages].count, info
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
