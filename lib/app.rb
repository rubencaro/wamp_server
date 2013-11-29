require 'log_helpers'
require 'forwardable'
require 'app/drivers/mongo'

module App

  @@driver = App::Drivers::Mongo

  extend SingleForwardable
  def_delegators :@@driver, :init_session, :save_prefix,
                       :clear_sessions, :remove_session

  def self.init
    @@driver.init
    @@driver.clear_sessions
  end

  def self.route(ws,call)
    H.log "Routing call: #{call}"
  end
end
