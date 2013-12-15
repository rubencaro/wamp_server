require 'rubygems'
require 'bundler/setup'
require 'em-synchrony'
require 'json'
$:.unshift File.expand_path('lib')
require 'wamp_server'
require 'app'
require 'log_helpers'

before_start = lambda{ App.init }
onprefix = lambda{ |opts| App.save_prefix opts[:ws], opts[:prefix], opts[:uri] }
onwelcome = lambda{ |opts| App.init_session opts[:ws] }

oncall = lambda do |opts|
  uri = App.solve_uri opts[:ws], opts[:curie]
  controller, action = App.parse_uri uri
  App.route(controller, action, *opts[:args])
end

onpublish = lambda do |opts|
  uri = App.solve_uri opts[:ws], opts[:curie]
  App.get_suscriptions uri
end

onsubscribe = lambda do |opts|
  uri = App.solve_uri opts[:ws], opts[:curie]
  App.subscribe opts[:ws], uri
end

onunsubscribe = lambda do |opts|
  uri = App.solve_uri opts[:ws], opts[:curie]
  App.unsubscribe opts[:ws], uri
end

onclose = lambda{ |opts| App.remove_session opts[:ws] }

WAMP.start_server before_start: before_start, onprefix: onprefix,
                  onwelcome: onwelcome, oncall: oncall,
                  onpublish: onpublish, onclose: onclose,
                  onsubscribe: onsubscribe, onunsubscribe: onunsubscribe
