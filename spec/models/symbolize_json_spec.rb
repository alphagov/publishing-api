require "rails_helper"

RSpec.describe SymbolizeJSON do
  subject { FactoryGirl.build(:draft_content_item) }

  it "doesn't affect non-json columns" do
    content_id = SecureRandom.uuid

    subject.content_id = content_id
    subject.public_updated_at = Date.new(2000, 1, 1)

    subject.save!
    subject.reload

    expect(subject.content_id).to eq(content_id)
    expect(subject.public_updated_at).to eq(Date.new(2000, 1, 1))
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
      subject.details = ["foo"]

      subject.save!
      subject.reload

      expect(subject.details).to eq(["foo"])
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
