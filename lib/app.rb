require 'log_helpers'
require 'string_helpers'
require 'forwardable'
require 'app/drivers/memory'
Dir['./lib/app/controllers/*_controller.rb'].each{ |f| require File.expand_path(f) }

module App
  extend SingleForwardable

  def self.delegate
    def_delegators @@driver, :init_session, :save_prefix, :solve_uri,
                         :clear_sessions, :remove_session
  end

  def self.driver; @@driver; end

=begin
  Rellena el hash routes usando todos los constants *Controller como primer nivel
  y los métodos *_action como segundo nivel, y guardando el método como valor final:

  routes = {
    'a_controller' => {
      'a_action' => AController.a_action
    }
  }

  El enrutamiento se reduce a buscar una key en un hash.
=end
  def self.fill_routes(routes)
    controllers = App.constants.grep /^.+Controller$/
    controllers.each do |c|
      controller = App.const_get(c)
      c = c.to_s.sub(/Controller$/,'')
      actions = controller.methods.grep(/^.+_action$/)
      actions.each do |a|
        routes[c.to_s.underscore] ||= {}
        routes[c.to_s.underscore][a.to_s.sub(/_action$/,'')] = controller.method(a)
      end
    end
  end

  def self.init(driver = App::Drivers::Memory)
    @@driver = driver
    delegate
    @@driver.init
    @@driver.clear_sessions
    @@routes = {}
    fill_routes @@routes
  end

  def self.route(controller, action, *args)
    H.log "Routing #{controller}##{action} #{args}"
    if @@routes[controller].nil? or
        @@routes[controller][action].nil? then
      raise "Not Found #{controller}##{action}"
    end

    return @@routes[controller][action].call(*args)
  end

  def self.parse_uri(uri)
    uri =~ %r_http://([^#]+)#(.+)_
    [$1, $2]
  end

  def self.echo(*args)
    args
  end
end
