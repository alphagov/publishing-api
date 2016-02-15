RSpec.shared_examples DescriptionOverrides do
  it "persists descriptions of different types" do
    subject.description = nil
    subject.save!
    expect(subject.reload.description).to eq(nil)

    subject.description = "string"
    subject.save!
    expect(subject.reload.description).to eq("string")

    subject.description = ["array"]
    subject.save!
    expect(subject.reload.description).to eq ["array"]
  end

  it "returns the correct #attributes" do
    subject.description = nil
    description = subject.attributes["description"]
    expect(description).to eq(nil)

    subject.description = "string"
    description = subject.attributes["description"]
    expect(description).to eq("string")

    subject.description = ["array"]
    description = subject.attributes["description"]
    expect(description).to eq ["array"]
  end

  it "returns the correct .column_defaults" do
    defaults = described_class.column_defaults
    expect(defaults["description"]).to eq(nil)
  end
end
