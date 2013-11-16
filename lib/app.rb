require 'wamp_server'
require 'fiber'

module AppLogic
  def self.do_things
    res = MyServer.db.collection('bogus').find( :$where => "sleep(2000)" ).count
    "Done #{Thread.current.to_s}, #{Fiber.current.to_s} res:#{res.inspect}"
  end
end
