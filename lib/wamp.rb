# see http://wamp.ws/spec

module WAMP

  WELCOME = 0
  PREFIX = 1
  CALL = 2
  CALLRESULT = 3
  CALLERROR = 4
  SUBSCRIBE = 5
  UNSUBSCRIBE = 6
  PUBLISH = 7
  EVENT = 8

  def self.new_session_id
    Time.now.strftime('%s%9N')
  end

end
