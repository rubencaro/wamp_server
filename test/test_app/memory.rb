module TestApp
  module Drivers
    class Memory
      @@db = {}

      def self.get_db(table); @@db[table].map{|k,v| v[:_id] = k; v};end

      def self.init
        @@db = {}
        clear_sessions
      end

      def self.init_session(ws)
        @@db['sessions'] ||= {}
        @@db['sessions'][ws.object_id] = {}
        ws.object_id
      end

      def self.save_prefix(ws,prefix,uri)
        @@db['sessions'][ws.object_id][:prefixes] ||= {}
        @@db['sessions'][ws.object_id][:prefixes][prefix] = uri
      end

      def self.solve_uri(ws,uri)
        return uri if @@db['sessions'][ws.object_id].nil? or
                        @@db['sessions'][ws.object_id][:prefixes].nil?

        prefix, action = uri.split(':') # 'prefix:action'
        solved = @@db['sessions'][ws.object_id][:prefixes][prefix]
        solved ? "#{solved}#{action}" : uri
      end

      def self.clear_sessions
        @@db['sessions'] = {}
      end

      def self.remove_session(ws)
        @@db['sessions'].delete ws.object_id
      end

      def self.subscribe(ws,uri)
        @@db['sessions'][ws.object_id][:subscriptions] ||= {}
        @@db['sessions'][ws.object_id][:subscriptions][uri] = {}
      end

      def self.unsubscribe(ws,uri)
        return if @@db['sessions'][ws.object_id][:subscriptions].nil?
        @@db['sessions'][ws.object_id][:subscriptions].delete uri
      end

      def self.get_suscriptions(uri)
        @@db['sessions'].select do |id,sess|
          subs = sess[:subscriptions]
          subs and subs[uri]
        end.keys
      end

    end
  end
end
