require_relative "lib/version"

Gem::Specification.new do |s|
  s.name        = "wamp_server"
  s.version     = WAMP::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ruben Caro"]
  s.email       = ["ruben.caro@lanuez.org"]
  s.homepage    = "https://github.com/rubencaro/wamp_server"
  s.summary = "Simple WAMPv1 compliant server"
  s.description = "WAMPv1 compliant server to be used "+
                  "as a skeleton for nice and shining Ruby apps, based on "+
                  "WebSocket EventMachine Server."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ["lib"]
  s.license = "GPLv3"

  s.required_ruby_version     = '>= 2.0.0'

  s.add_dependency 'websocket-eventmachine-server'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'websocket-eventmachine-client'
  s.add_development_dependency 'em-synchrony'
end
