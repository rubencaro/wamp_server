require 'rubygems'
require 'bundler/setup'
require_relative '../../lib/wamp_server'
require_relative 'test_app'

module MyServer

  def before_start
    TestApp.init
  end

  def onprefix(opts)
    TestApp.save_prefix opts[:ws], opts[:prefix], opts[:uri]
  end

  def onwelcome(opts)
    TestApp.init_session opts[:ws]
  end

  def oncall(opts)
    uri = TestApp.solve_uri opts[:ws], opts[:curie]
    controller, action = TestApp.parse_uri uri
    TestApp.route(controller, action, *opts[:args])
  end

  def onpublish(opts)
    uri = TestApp.solve_uri opts[:ws], opts[:curie]
    subscribed = TestApp.get_suscriptions uri
    { :uri => uri, :subscribed => subscribed }
  end

  def onsubscribe(opts)
    uri = TestApp.solve_uri opts[:ws], opts[:curie]
    TestApp.subscribe opts[:ws], uri
  end

  def onunsubscribe(opts)
    uri = TestApp.solve_uri opts[:ws], opts[:curie]
    TestApp.unsubscribe opts[:ws], uri
  end

  def onclose(opts)
    TestApp.remove_session opts[:ws]
  end

end

WAMP.start_server MyServer
