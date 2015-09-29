module RequestHelpers
  module DerivedRepresentations
    def creates_no_derived_representations
      it "does not create any derived representations" do
        put_content_item

        expect(DraftContentItem.count).to eq(0)
        expect(LiveContentItem.count).to eq(0)
        expect(LinkSet.count).to eq(0)
      end
    end

    def creates_a_link_representation
      it "creates the LinkSet derived representation" do
        put_content_item
        expect(LinkSet.count).to eq(1)
      end

      it "gives the LinkSet derived representation a version of 1" do
        put_content_item
        expect(LinkSet.first.version).to eq(1)
      end

      context "a LinkSet record already exists" do
        before { LinkSet.create(content_id: content_item[:content_id], links: {}, version: 1) }

        it "updates the existing link record" do
          put_content_item
          expect(LinkSet.count).to eq(1)
          expect(LinkSet.last.links).to eq(content_item[:links].deep_stringify_keys)
        end

        it "increments the version number to 2" do
          put_content_item
          expect(LinkSet.first.version).to eq(2)
        end
      end
    end

    def creates_a_content_item_representation(representation_class, access_limited: false, immutable_base_path: false)
      it "creates the #{representation_class} derived representation" do
        put_content_item(body: content_item.to_json)

        expect(representation_class.count).to eq(1)

        item = representation_class.first

        expect(item.base_path).to eq(base_path)
        expect(item.content_id).to eq(content_item[:content_id])
        expect(item.details).to eq(content_item[:details].deep_stringify_keys)
        expect(item.format).to eq(content_item[:format])
        expect(item.locale).to eq(content_item[:locale])
        expect(item.publishing_app).to eq(content_item[:publishing_app])
        expect(item.rendering_app).to eq(content_item[:rendering_app])
        expect(item.public_updated_at).to eq(content_item[:public_updated_at])
        expect(item.description).to eq(content_item[:description])
        expect(item.title).to eq(content_item[:title])
        expect(item.routes).to eq(content_item[:routes].map(&:deep_stringify_keys))
        expect(item.redirects).to eq(content_item[:redirects].map(&:deep_stringify_keys))
        expect(item.metadata["need_ids"]).to eq(content_item[:need_ids])
        expect(item.metadata["phase"]).to eq(content_item[:phase])

        if access_limited
          expect(item.access_limited).to eq(content_item[:access_limited].deep_stringify_keys)
        end
      end

      it "gives the first #{representation_class} a version number of 1" do
        put_content_item

        expect(representation_class.first.version).to eq(1)
      end

      context "a #{representation_class} already exists" do
        before do
          representation_class.create(
            title: "An existing title",
            content_id: content_item[:content_id],
            locale: content_item[:locale],
            details: content_item[:details],
            metadata: {},
            base_path: base_path,
            version: 1
          )
        end

        it "updates the existing #{representation_class}" do
          put_content_item

          expect(representation_class.count).to eq(1)
          expect(representation_class.last.title).to eq(content_item[:title])
        end

        it "increments the version number to 2" do
          put_content_item
          expect(representation_class.first.version).to eq(2)
        end

        if immutable_base_path
          new_base_path = "/something-else"

          it "reports a validation error if attempting to change base_path" do
            put request_path.gsub(base_path, new_base_path), content_item.to_json

            expect(response.status).to eq(400)
            expect(JSON.parse(response.body)).to eq({"errors" => {"base_path" => "cannot change once item is live"}})
            expect(representation_class.count).to eq(1)
            expect(representation_class.first.base_path).to eq(base_path)
          end
        else
          it "allows the base_path to be changed" do
            new_base_path = "/something-else"

            stub_request(:put, Plek.find('draft-content-store') + "/content#{new_base_path}")

            put request_path.gsub(base_path, new_base_path), content_item.to_json

            expect(response.status).to eq(200)
            expect(representation_class.count).to eq(1)
            expect(representation_class.first.base_path).to eq(new_base_path)
          end
        end
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::DerivedRepresentations, :type => :request
