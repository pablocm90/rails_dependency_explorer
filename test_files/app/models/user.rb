# frozen_string_literal: true

class App::Models::User
  def validate_user
    Services::UserService.new.validate(self)
  end
end
