RSpec.shared_examples_for WellFormedContentTypesValidator do
  describe "validations" do
    describe "details" do
      it "is valid when the content types are well-formed" do
        subject.details = {
          body: [
            { content_type: "text/html", content: "<p>content</p>" },
            { content_type: "text/plain", content: "content" },
          ],
        }

        expect(subject).to be_valid
      end

      it "is invalid when the content types are not well-formed" do
        subject.details = {
          body: [
            { content_type: "text/html" },
            { content_type: "text/plain", content: "content" },
          ],
        }

        expect(subject).to be_invalid
      end

      it "is invalid when the text/html content type is not included" do
        subject.details = {
          body: [
            { content_type: "text/plain", content: "content" },
          ],
        }

        expect(subject).to be_invalid
      end
    end
  end
end
