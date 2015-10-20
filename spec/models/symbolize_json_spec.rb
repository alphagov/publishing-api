require "rails_helper"

RSpec.describe SymbolizeJSON do
  subject { FactoryGirl.build(:draft_content_item) }

  it "doesn't affect non-json columns" do
    subject.content_id = "content_id"
    subject.public_updated_at = Date.new(2000, 1, 1)

    subject.save!
    subject.reload

    expect(subject.content_id).to eq("content_id")
    expect(subject.public_updated_at).to eq(Date.new(2000, 1, 1))
  end

  context "json columns" do
    it "symbolizes hashes" do
      subject.metadata = { foo: "bar" }
      subject.details = { "foo" => "bar" }

      subject.save!
      subject.reload

      expect(subject.metadata).to eq(foo: "bar")
      expect(subject.details).to eq(foo: "bar")
    end

    it "symbolizes arrays" do
      subject.metadata = [{ foo: "bar" }]
      subject.details = [{ "foo" => "bar" }]

      subject.save!
      subject.reload

      expect(subject.metadata).to eq([{ foo: "bar" }])
      expect(subject.details).to eq([{ foo: "bar" }])
    end

    it "doesn't affect other JSON-compatible data types" do
      subject.metadata = 123
      subject.details = nil

      subject.save!
      subject.reload

      expect(subject.metadata).to eq(123)
      expect(subject.details).to eq(nil)
    end
  end
end
