require "rails_helper"

RSpec.describe ContentStorePayloadVersion do
  let(:content_item_id) { 10 }
  describe ".current_for" do
    it "returns the current value for the supplied content_item_id" do
      described_class.increment(content_item_id)
      expect(described_class.current_for(content_item_id)).to eq(1)
    end
  end

  describe ".increment" do
    context "when there is no record" do
      it "creates one" do
        described_class.increment(content_item_id)
        expect(described_class.count).to eq(1)
      end

      it "initializes current to 1" do
        described_class.increment(content_item_id)
        expect(described_class.last.current).to eq(1)
      end

      it "sets the content_item_id" do
        described_class.increment(content_item_id)
        expect(described_class.last.content_item_id).to eq(content_item_id)
      end

      it "returns the current value" do
        expect(described_class.increment(content_item_id)).to eq(1)
      end
    end

    context "when a record already exists" do
      let!(:content_store_payload_version) do
        described_class.create(
          content_item_id: content_item_id,
          current: 10
        )
      end

      it "increments the current value before returning it" do
        expect(described_class.increment(content_item_id))
          .to eq(11)
      end
    end
  end

  describe ContentStorePayloadVersion::V1 do
    describe ".current" do
      it "returns the current value from the nil content_item_id record" do
        described_class.increment
        expect(described_class.current).to eq(1)
      end
    end

    describe ".increment" do
      context "when there is no record" do
        it "creates one" do
          described_class.increment
          expect(ContentStorePayloadVersion.count).to eq(1)
        end

        it "sets content_item_id to null" do
          described_class.increment
          expect(ContentStorePayloadVersion.last.content_item_id).to be_nil
        end

        it "returns current value of 1" do
          expect(described_class.increment).to eq(1)
        end
      end

      context "when a record already exists" do
        let!(:content_store_payload_version) do
          ContentStorePayloadVersion.create(
            content_item_id: nil,
            current: 10
          )
        end

        it "increments the current value before returning it" do
          expect(described_class.increment)
            .to eq(11)
        end
      end
    end
  end
end
