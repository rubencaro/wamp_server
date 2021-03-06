require 'forwardable'
require_relative 'helpers'
require_relative 'memory'
require_relative 'test_controller'

module TestApp
  extend SingleForwardable

  def self.delegate
    def_delegators @@driver, :init_session, :save_prefix, :solve_uri,
                         :clear_sessions, :remove_session,
                         :subscribe, :unsubscribe, :get_suscriptions
  end

  def self.driver; @@driver; end

  def self.init(driver = TestApp::Drivers::Memory)
    @@driver = driver
    delegate
    @@driver.init
    @@driver.clear_sessions
    @@routes = {}
    fill_routes @@routes
  end

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
    controllers = TestApp.constants.grep /^.+Controller$/
    controllers.each do |c|
      controller = TestApp.const_get(c)
      c = c.to_s.sub(/Controller$/,'')
      actions = controller.methods.grep(/^.+_action$/)
      actions.each do |a|
        routes[c.to_s.underscore] ||= {}
        routes[c.to_s.underscore][a.to_s.sub(/_action$/,'')] = controller.method(a)
      end
    end
  end

  def self.route(controller, action, *args)
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
end
