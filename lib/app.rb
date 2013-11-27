require 'log_helpers'
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

  def self.save_prefix(ws,data)
    # data = [ TYPE_ID_PREFIX , prefix, URI ]
    op = { :$addToSet => { :prefixes => { :uri => data[2], :prefix => data[1] } }  }
    App.db['sessions'].update( { :ws => ws.object_id }, op)
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
