RSpec.shared_examples DefaultAttributes do
  before do
    subject.schema_name = "something that should be cleared"
    subject.routes = ["foo"]
  end

  let(:attributes) {
    {
      title: "New title",
    }
  }

  it "does not preserve any information from the existing item" do
    subject.assign_attributes_with_defaults(attributes)

    expect(subject.schema_name).to be_nil
    expect(subject.routes).to eq([])
  end

  it "assigns the new attributes" do
    subject.assign_attributes_with_defaults(attributes)
    expect(subject.title).to eq("New title")
  end

  it "assigns the description attributes correctly" do
    subject.assign_attributes_with_defaults({})
    expect(subject.description).to eq(nil)

    subject.assign_attributes_with_defaults(description: "foo")
    expect(subject.description).to eq("foo")
  end
end
