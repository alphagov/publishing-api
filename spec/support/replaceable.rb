RSpec.shared_examples Replaceable do
  context "an item exists with that content_id" do
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
        set_new_attributes(item)
      end
      verify_new_attributes_set
    end

    it "returns the updated item" do
      item = described_class.create_or_replace(payload)
      expect(item).to be_a(described_class)
    end
  end

  context "no item exists with that content_id" do
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

    before do
      existing.destroy
      draft.destroy if defined?(draft)
    end

    it "raises a CommandRetryableError in case of a duplicate constraint violation" do
      expect {
        described_class.create_or_replace(payload) do |existing|
          create(described_class, payload.slice(*described_class.query_keys))
        end
      }.to raise_error(CommandRetryableError)
    end
  end
end
