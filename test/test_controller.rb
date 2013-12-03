module App
  module TestController
    def self.get_db_action(*args)
      App.driver.get_db(*args)
    end
  end
end
