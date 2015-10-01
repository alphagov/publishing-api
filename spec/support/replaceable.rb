RSpec.shared_examples Replaceable do
  let(:payload) {
    build(described_class).as_json.symbolize_keys.except(:format, :routes).merge(content_id: content_id, title: "New title")
  }

  context "an item exists with that content_id" do

    let(:existing) { create(described_class) }
    let(:content_id) { existing.content_id }

    it "replaces an existing instance by content id" do
      described_class.create_or_replace(payload)
      expect(described_class.count).to eq(1)
      item = described_class.first
      expect(item.content_id).to eq(content_id)
      expect(item.id).to eq(existing.id)
      expect(item.title).to eq("New title")
    end

    it "does not preserve any information from the existing item" do
      described_class.create_or_replace(payload)
      expect(described_class.first.format).to be_nil
      expect(described_class.first.routes).to be_nil
    end

    it "increases the version number" do
      described_class.create_or_replace(payload)
      expect(described_class.first.version).to eq(2)
    end
  end

  context "no item exists with that content_id" do
    let(:content_id) { SecureRandom.uuid }

    it "creates a new instance" do
      described_class.create_or_replace(payload)
      expect(described_class.count).to eq(1)
      expect(described_class.first.content_id).to eq(content_id)
      expect(described_class.first.title).to eq("New title")
    end

    it "sets the version number to 1" do
      described_class.create_or_replace(payload)
      expect(described_class.first.version).to eq(1)
    end
  end
end
