require 'log_helpers'
module App
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
      end

      def self.save_prefix(ws,data)
        # data = [ TYPE_ID_PREFIX , prefix, URI ]
        _, prefix, uri = data
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

    end
  end
end
