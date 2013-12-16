module TestApp
  module TestController
    def self.get_db_action(*args)
      TestApp.driver.get_db(*args)
    end

    def self.subscribe_test(*args)
      TestApp.driver.subscribe(*args)
    end
  end
end
