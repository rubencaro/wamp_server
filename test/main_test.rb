require 'helper'

class TestMain < Minitest::Test

  def test_main
    onopen = lambda{ |ws| puts 'onopen'; assert true }
    onmessage = lambda{ |ws,msg,type| puts "Server responded: #{msg}"; assert true; ws.close }
    onclose = lambda{ |ws| puts 'onclose'; assert true; EM.stop }
    run_ws_client onopen, onmessage, onclose
  end

end
