RSpec.shared_examples DefaultAttributes do
  before do
    subject.format = "something that should be cleared"
    subject.routes = ["foo"]
    subject.version = 1
  end

  let(:attributes) {
    {
      title: "New title",
    }
  }

  it "does not preserve any information from the existing item" do
    subject.assign_attributes_with_defaults(attributes)

    expect(subject.format).to be_nil
    expect(subject.routes).to eq([])
  end

  it "assigns the new attributes" do
    subject.assign_attributes_with_defaults(attributes)
    expect(subject.title).to eq("New title")
  end

  it "increases the version number if none was specified in the payload" do
    subject.assign_attributes_with_defaults(attributes)
    expect(subject.version).to eq(2)
  end

  it "uses the provided version number in preference to calculating one if provided" do
    subject.assign_attributes_with_defaults(attributes.merge(version: 99))
    expect(subject.version).to eq(99)
  end
end
