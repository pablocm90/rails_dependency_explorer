module App
  module Models
    class User
      def validate
        Services::UserService.new
      end
    end
  end
end
