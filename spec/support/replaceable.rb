RSpec.shared_examples Replaceable do
  let(:payload) {
    build(described_class)
      .as_json
      .deep_symbolize_keys
      .except(:format, :routes)
      .merge(new_attributes)
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
      verify_new_attributes_set
    end

    it "provides a mechanism to mutate the object before it is saved" do
      described_class.create_or_replace(payload) do |item|
        item.version = 123
      end
      expect(described_class.last.version).to eq(123)
    end

    it "returns the updated item" do
      item = described_class.create_or_replace(payload)
      expect(item).to be_a(described_class)
    end
  end

  context "no item exists with that content_id" do
    let(:content_id) { SecureRandom.uuid }

    it "creates a new instance" do
      described_class.create_or_replace(payload)
      expect(described_class.count).to eq(1)
      expect(described_class.first.content_id).to eq(content_id)
      verify_new_attributes_set
    end

    it "sets the version number to 1" do
      described_class.create_or_replace(payload)
      expect(described_class.first.version).to eq(1)
    end

    it "uses the provided version number in preference to calculating one if provided" do
      described_class.create_or_replace(payload.merge("version" => 99))
      expect(described_class.first.version).to eq(99)
    end

    it "returns the created item" do
      item = described_class.create_or_replace(payload)
      expect(item).to be_a(described_class)
    end
  end

  describe "retrying on race condition when inserting" do
    # There is a race condition when inserting a new entry. Between the read
    # query which is to check whether an item exists and the write of the new
    # item if none was found, another process may have simultaneously inserted
    # an item.
    #
    # In this scenario one of the transactions will hit a unique constraint
    # violation. The transaction should be retried from the beginning (including
    # creating a new event in the event log). We can signal to the EventLogger
    # class that we want to do this by raising a CommandRetryableError exception.

    let(:content_id) { SecureRandom.uuid }

    it "raises a CommandRetryableError in case of a duplicate constraint violation" do
      expect {
        described_class.create_or_replace(payload) do |existing|
          create(described_class, payload.slice(*described_class.query_keys))
        end
      }.to raise_error(CommandRetryableError)
    end
  end
end
