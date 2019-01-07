require "rails_helper"

RSpec.describe PathReservationsController, type: :controller do
  describe "reserve_path" do
    context "with a valid path reservation request" do
      let(:payload) {
        { publishing_app: "Foo" }
      }

      it "responds successfully" do
        post :reserve_path, params: { base_path: "foo" }, body: payload.to_json

        expect(response.status).to eq(200)
      end
    end

    context "with an invalid path reservation request" do
      let(:payload) {
        { publishing_app: nil }
      }

      it "responds with status 422" do
        post :reserve_path, params: { base_path: "///" }, body: payload.to_json

        expect(response.status).to eq(422)
      end
    end
  end
end
