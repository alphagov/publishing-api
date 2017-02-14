require "rails_helper"

RSpec.describe ContentConsistencyChecker do
  describe "#call" do
    describe "unknown content" do
      subject { described_class.new(SecureRandom.uuid).call }

      it "should have errors" do
        expect(subject).not_to be_empty
      end
    end

    describe "valid content" do
      let(:item) { FactoryGirl.create(:edition) }
      let(:body) do
        {
          schema_name: "guide",
          document_type: "guide",
          rendering_app: "frontend",
          publishing_app: "publisher"
        }
      end

      subject { described_class.new(item.document.content_id).call }

      it "should not have errors" do
        stub_content_store("draft", body, item.base_path)
        expect(subject).to be_empty
      end
    end

    describe "gone content" do
      let(:item) { FactoryGirl.create(:gone_edition) }

      subject { described_class.new(item.document.content_id).call }

      it "should not have errors" do
        stub_content_store("draft", {}, item.base_path, 410)
        expect(subject).to be_empty
      end
    end

    context "has redirects" do
      subject { described_class.new(item.document.content_id).call }

      context "item is published but not in the content store" do
        let(:item) { FactoryGirl.create(:redirect_live_edition) }
        before do
          stub_content_store("live", {}, item.base_path, 404)
        end

        it "should produce an error" do
          expect(subject.first).to match(/missing from the content store/)
        end
      end
    end

    context "has routes" do
      subject { described_class.new(item.document.content_id).call }

      context "item is gone but exists in the content store" do
        let(:item) { FactoryGirl.create(:gone_edition) }
        before do
          stub_content_store("draft", {}, item.base_path)
        end

        it "should produce an error" do
          expect(subject.first).to match(/Draft content is not gone in the content store/)
        end
      end

      context "item is published but not in the content store" do
        let(:item) { FactoryGirl.create(:live_edition) }
        before do
          stub_content_store("live", {}, item.base_path, 404)
        end

        it "should produce an error" do
          expect(subject.first).to match(/missing from the content store/)
        end
      end
    end
  end
end

def content_store_url(instance)
  prefix = instance == "draft" ? "draft-" : ""
  Plek.find("#{prefix}content-store")
end

def stub_content_store(instance, body, path, status = 200)
  stub_request(:get, "#{content_store_url(instance)}/content#{path}").
  and_return(status: status, body: body.to_json, headers: {})
end
