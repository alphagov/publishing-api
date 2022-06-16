RSpec.describe Document do
  subject { build(:document) }

  describe "validations" do
    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a content_id" do
      subject.content_id = nil
      expect(subject).to be_invalid
    end

    context "content_id" do
      it "accepts a UUID" do
        subject.content_id = "a7c48dac-f1c6-45a8-b5c1-5c407d45826f"
        expect(subject).to be_valid
      end

      it "does not accept an arbitrary string" do
        subject.content_id = "bacon"
        expect(subject).not_to be_valid
      end

      it "does not accept an empty string" do
        subject.content_id = ""
        expect(subject).not_to be_valid
      end
    end
  end
end
