require_relative 'helper'
require 'wamp'

class TestMain < Minitest::Test

#  def test_plain_ws
#    cb = lambda do |ws,msg,type,info|
#      ws.close
#    end
#    info = run_ws_client onmessage: cb
#    assert_equal 1, info[:messages].count
#  end

#  def test_welcome
#    @db = get_db
#    @db['sessions'].remove
#    cb = lambda do |ws,msg,type,info|
#      data = check_is_json msg
##      check_is_welcome data
#      ws.close
#    end
#    info = run_ws_client onmessage: cb
##    assert_equal 1, info[:messages].count
##    assert_equal 0, @db['sessions'].find().count
#  end

  def test_prefix
    @db = get_db
    @db['sessions'].remove
    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg

      ws.send ['hey'].to_json
#      check_is_welcome data
#      check_prefix_is_saved ws,data
      ws.close
    end
    info = run_ws_client onmessage: cb
#    assert_equal 1, info[:messages].count
#    assert_equal 0, @db['sessions'].find().count
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
    assert_equal 1, @db['sessions'].find(:ws => data[1]).count
  end

  def check_prefix_is_saved(ws,data)
    # [ TYPE_ID_PREFIX , prefix, URI ]
    uri = "http://example.com/simple/calc#"
    prefix = 'calc'
    ws.send [WAMP::PREFIX, prefix, uri].to_json
    s = @db['sessions'].find(:ws => data[1]).to_a.first
    H.spit s
    assert s['prefixes']
    assert_equal 1, s['prefixes'].count
    assert uri, s['prefixes'].first['uri']
    assert prefix, s['prefixes'].first['prefix']
  end

end
