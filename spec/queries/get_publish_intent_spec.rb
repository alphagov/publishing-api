RSpec.describe Queries::GetPublishIntent do
  let(:timeout) { false }

  before do
    request_stub = stub_request(:get, %r{.*content-store.*/publish-intent#{base_path}})

    if timeout
      request_stub.to_timeout
    else
      request_stub.to_return(status: status, body: body.to_json)
    end
  end

  context "when the content store responds with a 200" do
    let(:base_path) { "/vat-rates" }
    let(:status) { 200 }
    let(:body) { { foo: "bar" } }

    it "returns the body of the response from the content store" do
      result = subject.call(base_path)
      expect(result).to eq(body)
    end
  end

  context "when the content store responds with a 404" do
    let(:base_path) { "/missing" }
    let(:status) { 404 }
    let(:body) { {} }

    it "raises a command error" do
      expect {
        subject.call(base_path)
      }.to raise_error(CommandError, /could not find/i)
    end
  end

  context "when the content store times out" do
    let(:base_path) { "/timeout" }
    let(:timeout) { true }

    it "raises a command error" do
      expect {
        subject.call(base_path)
      }.to raise_error(CommandError, /content store timed out/i)
    end
  end
end
