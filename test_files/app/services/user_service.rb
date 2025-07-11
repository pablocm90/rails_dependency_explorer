# frozen_string_literal: true

class Services::UserService
  def validate(user)
    App::Models::User.find(user.id)
  end
end
