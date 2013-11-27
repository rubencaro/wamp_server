require 'log_helpers'
require 'wamp_server'
require 'mongo'
require 'mongo-em-patch'
require 'fiber_connection_pool'

module App

  def self.db=(value); @@db = value; end
  def self.db; @@db; end

  def self.init
    App.db = FiberConnectionPool.new(:size => 5) do
               Mongo::Connection.new.db('bogusdb')
             end
    clear_sessions
  end

  def self.init_session(ws)
    App.db['sessions'].insert({ :ws => ws.object_id })
  end

  def self.clear_sessions
    App.db['sessions'].remove
  end

  def self.remove_session(ws)
    H.log "Goobye #{ws.object_id}"
    App.db['sessions'].remove :ws => ws.object_id
  end

  def self.route(ws,call)
    H.log "Routing call: #{call}"
  end
end
