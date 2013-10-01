require 'helper'

class TestMain < Minitest::Test

  def test_main
    cb = lambda do |ws,msg,type,info|
      puts "Server said: #{msg}"
      if msg =~ /Took/ then
        ws.close
      else
        ws.send 'hey you too'
      end
    end
    info = run_ws_client onmessage: cb
    assert_equal 2, info[:messages].count
  end

end
