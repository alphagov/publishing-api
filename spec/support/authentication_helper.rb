module AuthenticationHelper
  module ControllerMixin
    def login_as(user)
      request.env['warden'] = double(
        authenticate!: true,
        authenticated?: true,
        user: user
      )
    end

    def login_as_stub_user
      user = FactoryGirl.create(:user, permissions: ['signin'])
      login_as(user)
    end
  end


  module RequestMixin
    def login_as(user)
      GDS::SSO.test_user = user
    end

    def login_as_stub_user
      user = FactoryGirl.create(:user, permissions: ['signin'])
      login_as(user)
    end
  end
end
