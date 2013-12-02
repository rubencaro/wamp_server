module TestController
  def self.get_db_action
    App.driver.get_db
  end
end
