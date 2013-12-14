require_relative 'helper'
require 'wamp'
require 'em-synchrony'

class TestMain < TestCase

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
      assert result.first['_id'], result
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
    H.announce
    controller = 'test' # TestController
    action = 'get_db'   # get_db_action
    args = ['sessions'] # 'table' argument for get_db_action
    callid = 'right one'
    cmd = [WAMP::CALL, callid, "http://#{controller}##{action}"] + args

    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg
      if data.first == WAMP::WELCOME then
        # send the right request right after welcome
        ws.send cmd.to_json
      elsif data.first == WAMP::CALLRESULT then
        # assert the right answer for the right request
        assert_equal 'right one', data[1], data
        result = data.last
        assert_equal 1, result.count, "#{result}"
        assert result.first['_id'], result

        # send the wrong request to force error
        callid = 'wrong one'
        controller = 'not_existing'
        cmd = [WAMP::CALL, callid, "http://#{controller}##{action}"] + args
        ws.send cmd.to_json
      else # WAMP::CALLERROR
        # assert the right answer for the wrong request
        assert_equal WAMP::CALLERROR, data.first, "#{data}"
        assert_equal 'wrong one', data[1], data
        assert data.last =~ /Not Found/
        ws.close
      end
    end
    info = run_ws_client onmessage: cb
    assert_equal 3, info[:messages].count, info
  end

  def test_subscribe_unsubscribe
    H.announce

    uri = 'http://test/subscribe_test'

    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg
      assert_equal WAMP::WELCOME, data.first, data

      # send the subscribe request
      ws.send [WAMP::SUBSCRIBE,uri].to_json

      # ensure it's subscribed
      #   subscription is saved within the session
      #   in a hash where the uri is the key
      result = call(ws,'get_db','sessions')
      session = result.select{|r| r['_id'] == data[1]}.first
      subs = session['subscriptions']
      assert subs && (subs.count == 1), session
      assert subs[uri], subs

      # send the unsubscribe request
      ws.send [WAMP::UNSUBSCRIBE,uri].to_json

      # ensure it's subscribed
      result = call(ws,'get_db','sessions')
      session = result.select{|r| r['_id'] == data[1]}.first
      subs = session['subscriptions']
      assert subs && subs.none?, session

      ws.close
    end
    info = run_ws_client onmessage: cb
    assert_equal 1, info[:messages].count, info
  end

  def test_publish
    H.announce

    socks = []
    n = 5
    uri = 'http://test/subscribe_test'

    cb = lambda do |ws,msg,type,info|
      data = check_is_json msg
      assert_equal WAMP::WELCOME, data.first, data
      sid = data[1]

      # run n satellite clients and subscribe them to our topic
      sent = 0
      subscribe_cb = lambda do |ws_sat,msg,type,info|
        socks << ws_sat # save it to be closed afterwards
        ws_sat.send [WAMP::SUBSCRIBE,uri].to_json
        sent += 1
      end
      n.times do
        run_satellite_ws_client info, :onmessage => subscribe_cb
      end

      # ensure we have audience
      timer = EM::Timer.new(5){ assert false, "Waited too much !" }
      while(sent < n) do EM::Synchrony.sleep(0.1) end
      timer.cancel

      sessions = call(ws,'get_db','sessions')
      assert_equal n+1, sessions.count, sessions
      sessions.reject{|s| s['_id'] == sid}.each do |s|
        subs = s['subscriptions']
        assert subs && (subs.count == 1), s
        assert subs[uri], subs
      end

      # publish

      # test is published to n subscribers

      # test is received by n subscribers

      socks.each{ |s| s.close }
      ws.close
    end
    info = run_ws_client onmessage: cb
    H.spit info

    # welcome
    # publish
    # test is published to n subscribers

    # test is received by n subscribers

    todo
  end

  private

  def check_is_welcome(data)
    # [ TYPE_ID_WELCOME , sessionId , protocolVersion, serverIdent ]
    assert_equal 4, data.count
    assert_equal WAMP::WELCOME, data[0]
    assert_equal 1, data[2] # protocol version
  end

end
