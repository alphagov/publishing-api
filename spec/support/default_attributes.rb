RSpec.shared_examples DefaultAttributes do
  before do
    subject.format = "something that should be cleared"
    subject.routes = ["foo"]
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
end
