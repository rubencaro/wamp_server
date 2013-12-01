require 'log_helpers'
require 'forwardable'
require 'app/drivers/memory'
require 'app/drivers/mongo'

module App
  extend SingleForwardable

  def self.delegate
    def_delegators @@driver, :init_session, :save_prefix, :solve_uri,
                         :clear_sessions, :remove_session, :get_db
  end

  def self.init(driver = App::Drivers::Memory)
    @@driver = driver
    delegate
    @@driver.init
    @@driver.clear_sessions
  end

  def self.route(ws,call)
    H.log "Routing call: #{call}"
  end

  def self.parse_uri(uri)
    uri =~ %r_http://([^#]+)#(.+)_
    [$1, $2]
  end

  def self.echo(*args)
    args
  end
end
