module AuthenticationHelper
  module ControllerMixin
    def login_as(user)
      request.env["warden"] = double(
        authenticate!: true,
        authenticated?: true,
        user:,
      )
    end

    def login_as_stub_user
      user = create(:user, permissions: %w[signin])
      login_as(user)
    end
  end

  module RequestMixin
    def login_as(user)
      GDS::SSO.test_user = user
    end

    def login_as_stub_user
      user = create(:user, permissions: %w[signin])
      login_as(user)
    end

    def logout
      GDS::SSO.test_user = nil
      User.delete_all
    end
  end
end
