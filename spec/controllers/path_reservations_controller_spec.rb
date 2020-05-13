require "rails_helper"

RSpec.describe PathReservationsController, type: :controller do
  describe "reserve_path" do
    context "with a valid path reservation request" do
      let(:payload) do
        { publishing_app: "Foo" }
      end

      it "responds successfully" do
        post :reserve_path, params: { base_path: "foo" }, body: payload.to_json

        expect(response.status).to eq(200)
      end
    end

    context "with an invalid path reservation request" do
      let(:payload) do
        { publishing_app: nil }
      end

      it "responds with status 422" do
        post :reserve_path, params: { base_path: "///" }, body: payload.to_json

        expect(response.status).to eq(422)
      end
    end
  end

  describe "unreserve_path" do
    let(:payload) { { publishing_app: "foo" } }

    context "with a valid path unreservation request" do
      it "responds successfuly" do
        create(:path_reservation, base_path: "/bar", publishing_app: "foo")
        delete :unreserve_path, params: { base_path: "bar" }, body: payload.to_json
        expect(response.status).to eq(200)
      end
    end

    context "with an invalid path unreservation request" do
      it "responds with status 422" do
        create(:path_reservation, base_path: "/bar")
        delete :unreserve_path, params: { base_path: "bar" }, body: payload.to_json
        expect(response.status).to eq(422)
      end
    end

    context "with a non-existant path unreservation request" do
      it "responds with status 404" do
        delete :unreserve_path, params: { base_path: "bar" }, body: payload.to_json
        expect(response.status).to eq(404)
      end
    end
  end
end
