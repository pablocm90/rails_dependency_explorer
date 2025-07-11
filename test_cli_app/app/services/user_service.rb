module Services
  class UserService
    def process
      App::Models::User.find(1)
    end
  end
end
