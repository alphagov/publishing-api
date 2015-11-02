require "rails_helper"

RSpec.describe "PUT /paths", type: :request do

  let(:request_body) { payload.to_json }

  def do_request(body: request_body, headers: {})
    put request_path, body, headers
  end

  context "with path /vat-rates" do
    let(:request_path) { "/paths#{base_path}" }
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
      }.to change(PathReservation, :count).by(1)
    end

    logs_event('ReservePath', expected_payload_proc: -> { payload.merge(base_path: base_path) } )
  end
end
