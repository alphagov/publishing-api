RSpec.describe Commands::V2::PutContentValidator do
  let(:payload) { { publishing_app: "foo", base_path: "/hello" } }
  let(:command) { instance_double(Commands::V2::PutContent) }
  subject { described_class.new(payload, command) }

  describe "validate" do
    context "schema validation fails" do
      let(:errors) do
        [{ schema: "a", fragment: "b", message: "c", failed_attribute: "d" }]
      end
      let(:validator) do
        instance_double(SchemaValidator, valid?: false, errors:)
      end
      before do
        allow(SchemaValidator).to receive(:new).and_return(validator)
      end

      it "raises command error and exits" do
        expect(PathReservation).not_to receive(:reserve_base_path!)
        expect { subject.validate }.to raise_error(CommandError) do |error|
          expect(error.code).to eq 422
          expect(error.error_code).to eq :schema_validation_failed
          expect(error.error_details).to eq errors
        end
      end
    end

    context "schema validation passes" do
      let(:validator) { instance_double(SchemaValidator, valid?: true) }

      before { allow(SchemaValidator).to receive(:new).and_return(validator) }

      it "doesn't raise anything" do
        expect { subject.validate }.not_to raise_error
      end

      context "without a publishing_app" do
        before { payload.delete(:publishing_app) }

        it "raises an error" do
          expect {
            subject.validate
          }.to raise_error(CommandError, /publishing_app is required/)
        end
      end

      context "with an invalid base_path" do
        let(:payload) { { publishing_app: "foo", base_path: "/Hello", schema_name: "guide" } }

        it "raises an error" do
          expect {
            subject.validate
          }.to raise_error(CommandError, /base_path did not conform to standard/)
        end

        context "when the content item is a redirect" do
          let(:payload) { { publishing_app: "foo", base_path: "/Hello", schema_name: "redirect" } }

          it "doesn't raise anything" do
            expect { subject.validate }.not_to raise_error
          end
        end
      end
    end
  end
end
