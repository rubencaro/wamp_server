require 'mongo'
require 'em-synchrony'
require 'mongo-em-patch'
require 'fiber_connection_pool'

module App
  module Drivers
    class Mongo

      def self.init
        @@db = FiberConnectionPool.new(:size => 5) do
                ::Mongo::Connection.new.db('bogusdb')
              end
        clear_sessions
      end

      def self.init_session(ws)
        @@db['sessions'].insert({ :ws => ws.object_id })
      end

      def self.save_prefix(ws,data)
        # data = [ TYPE_ID_PREFIX , prefix, URI ]
        op = { :$addToSet => { :prefixes => { :uri => data[2], :prefix => data[1] } }  }
        @@db['sessions'].update( { :ws => ws.object_id }, op)
      end

      def self.clear_sessions
        @@db['sessions'].remove
      end

      def self.remove_session(ws)
        @@db['sessions'].remove :ws => ws.object_id
      end

    end
  end
end
