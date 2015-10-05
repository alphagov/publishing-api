module RequestHelpers
  module DerivedRepresentations
    def creates_no_derived_representations
      it "does not create any derived representations" do
        do_request

        expect(DraftContentItem.count).to eq(0)
        expect(LiveContentItem.count).to eq(0)
        expect(LinkSet.count).to eq(0)
      end
    end

    def creates_a_link_representation(expected_attributes: )
      it "creates the LinkSet derived representation" do
        do_request
        expect(LinkSet.count).to eq(1)
      end

      it "gives the LinkSet derived representation a version of 1" do
        do_request
        expect(LinkSet.first.version).to eq(1)
      end

      context "a LinkSet record already exists" do
        before { LinkSet.create(content_id: expected_attributes[:content_id], links: {}, version: 1) }

        it "updates the existing link record" do
          do_request
          expect(LinkSet.count).to eq(1)
          expect(LinkSet.last.links).to eq(expected_attributes[:links].deep_stringify_keys)
        end

        it "increments the version number to 2" do
          do_request
          expect(LinkSet.first.version).to eq(2)
        end
      end
    end

    def creates_a_content_item_representation(representation_class, expected_attributes_proc:, access_limited: false)
      let(:expected_attributes) {
        instance_exec(&expected_attributes_proc)
      }

      it "creates the #{representation_class} derived representation" do
        do_request

        expect(representation_class.count).to eq(1)

        item = representation_class.first

        expect(item.base_path).to eq(base_path)
        expect(item.content_id).to eq(expected_attributes[:content_id])
        expect(item.details).to eq(expected_attributes[:details].deep_stringify_keys)
        expect(item.format).to eq(expected_attributes[:format])
        expect(item.locale).to eq(expected_attributes[:locale])
        expect(item.publishing_app).to eq(expected_attributes[:publishing_app])
        expect(item.rendering_app).to eq(expected_attributes[:rendering_app])
        expect(item.public_updated_at).to eq(expected_attributes[:public_updated_at])
        expect(item.description).to eq(expected_attributes[:description])
        expect(item.title).to eq(expected_attributes[:title])
        expect(item.routes).to eq(expected_attributes[:routes].map(&:deep_stringify_keys))
        expect(item.redirects).to eq(expected_attributes[:redirects].map(&:deep_stringify_keys))
        expect(item.metadata["need_ids"]).to eq(expected_attributes[:need_ids])
        expect(item.metadata["phase"]).to eq(expected_attributes[:phase])

        if access_limited
          expect(item.access_limited).to eq(expected_attributes[:access_limited].deep_stringify_keys)
        end
      end

      it "gives the first #{representation_class} a version number of 1" do
        do_request

        expect(representation_class.first.version).to eq(1)
      end

      context "a #{representation_class} already exists" do
        before do
          representation_class.create(
            title: "An existing title",
            content_id: expected_attributes[:content_id],
            locale: expected_attributes[:locale],
            details: expected_attributes[:details],
            metadata: {},
            base_path: base_path,
            version: 1
          )
        end

        it "updates the existing #{representation_class}" do
          do_request

          expect(representation_class.count).to eq(1)
          expect(representation_class.last.title).to eq(expected_attributes[:title])
        end

        it "increments the version number to 2" do
          do_request
          expect(representation_class.first.version).to eq(2)
        end
      end
    end

    def prevents_base_path_from_being_changed(representation_class)
      context "a #{representation_class} already exists" do
        before do
          representation_class.create!(
            title: "An existing title",
            content_id: expected_attributes[:content_id],
            locale: expected_attributes[:locale],
            details: expected_attributes[:details],
            metadata: {},
            base_path: base_path,
            version: 1
          )
        end

        it "reports a validation error if attempting to change base_path" do
          new_base_path = "/something-else"

          put request_path.gsub(base_path, new_base_path), request_body

          expect(response.status).to eq(400)
          expect(JSON.parse(response.body)).to eq({"errors" => {"base_path" => "cannot change once item is live"}})
          expect(representation_class.count).to eq(1)
          expect(representation_class.first.base_path).to eq(base_path)
        end
      end
    end

    def allows_base_path_to_be_changed(representation_class)
      context "a #{representation_class} already exists" do
        before do
          representation_class.create!(
            title: "An existing title",
            content_id: expected_attributes[:content_id],
            locale: expected_attributes[:locale],
            details: expected_attributes[:details],
            metadata: {},
            base_path: base_path,
            version: 1
          )
        end

        it "allows the base_path to be changed" do
          new_base_path = "/something-else"

          stub_request(:put, Plek.find('draft-content-store') + "/content#{new_base_path}")

          put request_path.gsub(base_path, new_base_path), request_body

          expect(response.status).to eq(200)
          expect(representation_class.count).to eq(1)
          expect(representation_class.first.base_path).to eq(new_base_path)
        end
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::DerivedRepresentations, :type => :request
