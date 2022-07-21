RSpec.describe "PUT /paths", type: :request do
  let(:request_body) { payload.to_json }

  def do_request(body: request_body, headers: {})
    put request_path, params: body, headers: headers
  end

  context "with path /vat-rates" do
    let(:request_path) { "/paths#{base_path}" }
    let(:payload) do
      {
        publishing_app: "publisher",
      }
    end

    it "responds successfully" do
      do_request

      expect(response.status).to eq(200)
    end

    it "reserves a new path" do
      expect {
        do_request
      }.to change(PathReservation, :count).by(1)
    end

    context "with override_existing set" do
      before do
        create(:path_reservation, base_path: base_path, publishing_app: "another")
        payload.merge!(override_existing: true)
      end

      it "updates an existing path" do
        expect {
          do_request
        }.not_to change(PathReservation, :count)

        expect(PathReservation.last.publishing_app).to eq("publisher")
      end
    end
  end
end
