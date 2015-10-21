require "rails_helper"

RSpec.describe "PUT /paths", type: :request do

  let(:request_body) { payload.to_json }

  def do_request(body: request_body, headers: {})
    put request_path, body, headers
  end

  context "with path /foo" do
    let(:request_path) { "/paths/foo" }
    let(:payload) {
      {
        publishing_app: "publisher",
      }
    }

    it "responds successfully" do
      do_request

      expect(response.status).to eq(200)
    end

    it "reserves a new path" do
      expect {
        do_request
      }.to change(UrlReservation, :count).by(1)
    end

  end
end


