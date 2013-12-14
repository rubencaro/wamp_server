require 'mongo'
require 'em-synchrony'
require 'mongo-em-patch'
require 'fiber_connection_pool'

module App
  module Drivers
    class Mongo
      @@db = nil

      def self.get_db(table); @@db[table].find.to_a;end

      def self.init
        @@db = FiberConnectionPool.new(:size => 5) do
                ::Mongo::Connection.new.db('bogusdb')
              end
        clear_sessions
      end

      def self.init_session(ws)
        @@db['sessions'].insert({ :_id => ws.object_id })
      end

      def self.save_prefix(ws,data)
        # data = [ TYPE_ID_PREFIX , prefix, URI ]
        _, prefix, uri = data
        op = { :$set => { "prefixes.#{prefix}" => uri }  }
        @@db['sessions'].update( { :_id => ws.object_id }, op)
      end

      def self.solve_uri(ws,uri)
        prefix, action = uri.split(':') # 'prefix:action'
        session = @@db['sessions'].find(:_id => ws.object_id, "prefixes.#{prefix}" => { :$exists => true }).to_a.first
        return uri if session.nil?
        solved = session['prefixes'][prefix]
        solved ? "#{solved}#{action}" : uri
      end

      def self.clear_sessions
        @@db['sessions'].remove
      end

      def self.remove_session(ws)
        @@db['sessions'].remove :_id => ws.object_id
      end

      def self.subscribe(ws,data)
        # data = [ TYPE_ID_SUBSCRIBE , topicURI ]
        op = { :$set => { "subscriptions.#{data[1]}" => {} }  }
        @@db['sessions'].update( { :_id => ws.object_id }, op)
      end

      def self.unsubscribe(ws,data)
        # data = [ TYPE_ID_UNSUBSCRIBE , topicURI ]
        op = { :$unset => { "subscriptions.#{data[1]}" => '' }  }
        @@db['sessions'].update( { :_id => ws.object_id }, op)
      end

    end
  end
end
