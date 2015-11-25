RSpec.shared_examples Replaceable do
  context "an item exists with these query_keys" do
    it "replaces an existing instance by query_keys" do
      expect {
        described_class.create_or_replace(payload)
      }.not_to change(described_class, :count)

      item = described_class.first
      described_class.query_keys do |key|
        expect(item.send(key)).to eq(payload[key.to_s])
      end
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
      expect {
        described_class.create_or_replace(another_payload)
      }.to change(described_class, :count).by(1)

      instance = described_class.last
      described_class.query_keys.each do |key|
        expect(instance.send(key)).to eq(another_payload.fetch(key))
      end
      verify_new_attributes_set
    end

    it "returns the created item" do
      item = described_class.create_or_replace(another_payload)
      expect(item).to be_a(described_class)
    end
  end

  # We should not let users of our API specify the version number for the
  # record to be saved. This should be handled by our application as it is
  # a workflow consideration.
  if described_class.column_names.include?("version")
    it "does not assign a version from the payload if one is provided" do
      described_class.create_or_replace(payload.merge(version: 123))
      expect(described_class.last.version).to_not eq(123)
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
    end

    context "for a single record" do
      it "raises a CommandRetryableError in case of a duplicate constraint violation" do
        expect {
          described_class.create_or_replace(payload) do |existing|
            create(described_class, payload.slice(*described_class.query_keys))
          end
        }.to raise_error(CommandRetryableError)
      end
    end

    context "for an object graph" do
      it "raises a CommandRetryableError in case of a duplicate constraint violation" do
        expect {
          described_class.create_or_replace(payload) do |existing|
            create(described_class, payload.slice(*described_class.query_keys))

            version = Version.new(target: existing)
            version.increment
            version.save!
          end
        }.to raise_error(CommandRetryableError)
      end
    end
  end
end
