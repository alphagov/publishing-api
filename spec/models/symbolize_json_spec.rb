RSpec.describe SymbolizeJSON do
  subject { build(:draft_edition) }

  it "doesn't affect non-json columns" do
    subject.public_updated_at = Date.new(2000, 1, 1)

    subject.save!
    subject.reload

    expect(subject.public_updated_at).to eq(Date.new(2000, 1, 1))
  end

  it "emits times in different timezones as UTC" do
    subject.public_updated_at = Time.utc(2000, 1, 1).in_time_zone("Eastern Time (US & Canada)")

    subject.save!
    subject.reload

    expect(subject.public_updated_at).to eq(Time.utc(2000, 1, 1))
  end

  context "json columns" do
    it "symbolizes hashes" do
      subject.details = { "foo" => "bar" }
      subject.save!
      subject.reload
      expect(subject.details).to eq(foo: "bar")

      subject.details = { foo: "bar" }
      subject.save!
      subject.reload
      expect(subject.details).to eq(foo: "bar")
    end

    it "symbolizes arrays of hashes" do
      subject.details = [{ "foo" => "bar" }]
      subject.save!
      subject.reload
      expect(subject.details).to eq([{ foo: "bar" }])

      subject.details = [{ foo: "bar" }]
      subject.save!
      subject.reload
      expect(subject.details).to eq([{ foo: "bar" }])
    end

    it "doesn't symbolize arrays of strings" do
      subject.details = %w[foo]

      subject.save!
      subject.reload

      expect(subject.details).to eq(%w[foo])
    end

    it "doesn't affect other JSON-compatible data types" do
      subject.details = 123
      subject.save!
      subject.reload
      expect(subject.details).to eq(123)

      subject.details = nil
      subject.save!
      subject.reload
      expect(subject.details).to eq(nil)
    end
  end
end
