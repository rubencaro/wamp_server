module App
  module TestController
    def self.get_db_action(*args)
      App.driver.get_db(*args)
    end

    def self.subscribe_test(*args)
      App.driver.subscribe(*args)
    end
  end
end
