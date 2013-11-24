require 'log_helpers'
require 'wamp_server'

module App

  def self.init
    clear_sessions
  end

  def self.init_session(ws)
    WampServer.db['sessions'].insert({ :ws => ws.object_id })
  end

  def self.clear_sessions
    WampServer.db['sessions'].remove
  end

  def self.remove_session(ws)
    H.log "Goobye #{ws.object_id}"
    WampServer.db['sessions'].remove :ws => ws.object_id
  end

  def self.route(ws,call)
    H.log "Routing call: #{call}"
  end
end
