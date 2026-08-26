RSpec.describe DeletePublishIntentJob do
  describe "when Content Store returns a 404 response" do
    let(:base_path) { "/foo" }
    let(:argument) do
      {
        "base_path" => base_path,
      }
    end

    before do
      stub_request(:delete, %r{.*content-store.*/publish-intent#{base_path}})
    end
    it "logs the error" do
      expect {
        subject.perform(argument)
      }.not_to raise_error
    end
  end
end
