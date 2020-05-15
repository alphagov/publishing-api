require "rails_helper"

RSpec.describe "DELETE /paths", type: :request do
  let(:request_body) { payload.to_json }

  def do_request(body: request_body, headers: {})
    delete request_path, params: body, headers: headers
  end

  context "with path /vat-rates" do
    let(:request_path) { "/paths#{base_path}" }
    let(:payload) { { publishing_app: "publisher" } }

    before do
      create(
        :path_reservation,
        base_path: base_path,
        publishing_app: "publisher",
      )
    end

    it "responds successfully" do
      do_request

      expect(response.status).to eq(200)
    end

    it "unreserves the path" do
      expect {
        do_request
      }.to change(PathReservation, :count).by(-1)
    end
  end
end
