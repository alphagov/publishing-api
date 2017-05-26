require "rails_helper"

RSpec.describe "Path reservation" do
  include_context "PutContent call"

  context "when there are no previous path reservations" do
    it "creates a path reservation" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(PathReservation, :count).by(1)

      reservation = PathReservation.last
      expect(reservation.base_path).to eq("/vat-rates")
      expect(reservation.publishing_app).to eq("publisher")
    end
  end

  context "when the base path has been reserved by another publishing app" do
    before do
      FactoryGirl.create(:path_reservation,
        base_path: base_path,
        publishing_app: "something-else"
      )
    end

    it "responds with an error" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect(response.status).to eq(422)
      expect(response.body).to match(/is already reserved/i)
    end
  end
end
