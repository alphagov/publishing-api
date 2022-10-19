require "gds-sso/lint/user_spec"

RSpec.describe User, type: :model do
  it_behaves_like "a gds-sso user class"

  context "setting the app_name" do
    let(:user) { User.new(email: "foobar@digital.cabinet-office.gov.uk") }
    it "sets the app_name from the email" do
      user.set_app_name!
      expect(user.app_name).to eq("foobar")
    end

    it "does not override existing app_name" do
      user.app_name = "barfoo"
      expect { user.set_app_name! }.not_to change(user, :app_name)
    end

    it "does nothing if email is blank" do
      user.email = ""
      expect { user.set_app_name! }.not_to change(user, :app_name)
    end
  end
end
