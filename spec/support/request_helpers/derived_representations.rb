module RequestHelpers
  module DerivedRepresentations
    def creates_no_derived_representations
      it "does not create any derived representations" do
        draft_count = DraftContentItem.count
        live_count = LiveContentItem.count
        link_count = LinkSet.count

        do_request

        expect(DraftContentItem.count).to eq(draft_count)
        expect(LiveContentItem.count).to eq(live_count)
        expect(LinkSet.count).to eq(link_count)
      end
    end

    def creates_a_link_representation(expected_attributes: )
      it "creates the LinkSet derived representation" do
        do_request
        expect(LinkSet.count).to eq(1)
      end

      it "gives the LinkSet derived representation a version of 1" do
        do_request

        version = Version.find_by!(target: LinkSet.first)
        expect(version.number).to eq(1)
      end

      context "a LinkSet record already exists" do
        before do
          link_set = FactoryGirl.create(:link_set,
            content_id: expected_attributes[:content_id],
          )

          FactoryGirl.create(:version, target: link_set, number: 1)
        end

        it "updates the existing link record" do
          do_request
          expect(LinkSet.count).to eq(1)
          links = Presenters::Queries::LinkSetPresenter.new(LinkSet.last).links
          expect(links).to eq(expected_attributes[:links])
        end

        it "increments the version number to 2" do
          do_request

          version = Version.find_by!(target: LinkSet.first)
          expect(version.number).to eq(2)
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
        expect(item.details).to eq(expected_attributes[:details])
        expect(item.format).to eq(expected_attributes[:format])
        expect(item.locale).to eq(expected_attributes[:locale])
        expect(item.publishing_app).to eq(expected_attributes[:publishing_app])
        expect(item.rendering_app).to eq(expected_attributes[:rendering_app])
        expect(item.public_updated_at).to eq(expected_attributes[:public_updated_at])
        expect(item.description).to eq(expected_attributes[:description])
        expect(item.title).to eq(expected_attributes[:title])
        expect(item.routes).to eq(expected_attributes[:routes])
        expect(item.redirects).to eq(expected_attributes[:redirects])
        expect(item.need_ids).to eq(expected_attributes[:need_ids])
        expect(item.phase).to eq(expected_attributes[:phase])
        expect(item.analytics_identifier).to eq(expected_attributes[:analytics_identifier])
        expect(item.update_type).to eq(expected_attributes[:update_type])

        if access_limited
          expect(item.access_limited).to eq(expected_attributes[:access_limited])
        end
      end

      it "gives the first #{representation_class} a version number of 1" do
        do_request

        version = Version.find_by!(target: representation_class.first)
        expect(version.number).to eq(1)
      end

      context "a #{representation_class} already exists" do
        before do
          factory_name = representation_class.to_s.underscore.to_sym

          live = (representation_class == LiveContentItem)

          item = FactoryGirl.create(
            factory_name,
            (:with_draft if live),
            title: "An existing title",
            content_id: expected_attributes[:content_id],
            locale: expected_attributes[:locale],
            details: expected_attributes[:details],
            base_path: base_path
          )

          FactoryGirl.create(:version, target: item, number: 1)

          if live
            FactoryGirl.create(:version, target: item.draft_content_item, number: 1)
          end
        end

        it "updates the existing #{representation_class}" do
          do_request

          expect(representation_class.count).to eq(1)
          expect(representation_class.last.title).to eq(expected_attributes[:title])
        end

        it "increments the version number to 2" do
          do_request

          version = Version.find_by!(target: representation_class.first)
          expect(version.number).to eq(2)
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
            base_path: base_path
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

    def allows_draft_base_path_to_be_changed
      context "a live content item already exists" do
        let(:new_base_path) { "/something-else" }
        let(:request_body) do
          content_item_params.merge(
            routes: [
              {
                path: new_base_path,
                type: "exact"
              }
            ]
          ).to_json
        end

        before do
          FactoryGirl.create(
            :live_content_item,
            title: "An existing title",
            content_id: expected_attributes[:content_id],
            locale: expected_attributes[:locale],
            details: expected_attributes[:details],
            base_path: base_path
          )

          stub_request(:put, Plek.find('draft-content-store') + "/content#{new_base_path}")
        end

        it "allows the base_path to be changed" do
          new_path = request_path.gsub(base_path, "/something-else")

          put new_path, request_body

          expect(response.status).to eq(200)
          expect(DraftContentItem.first.base_path).to eq(new_base_path)
        end
      end
    end

    def allows_live_base_path_to_be_changed
      context "a live content item already exists" do
        let(:new_base_path) { "/something-else" }
        let(:request_body) do
          content_item_params.merge(
            routes: [
              {
                path: new_base_path,
                type: "exact"
              }
            ]
          ).to_json
        end

        before do
          FactoryGirl.create(
            :live_content_item,
            title: "An existing title",
            content_id: expected_attributes[:content_id],
            locale: expected_attributes[:locale],
            details: expected_attributes[:details],
            base_path: base_path
          )

          stub_request(:put, Plek.find('draft-content-store') + "/content#{new_base_path}")
          stub_request(:put, Plek.find('content-store') + "/content#{new_base_path}")
        end

        it "allows the base_path to be changed" do
          new_path = request_path.gsub(base_path, new_base_path)

          put new_path, request_body

          expect(response.status).to eq(200)
          expect(LiveContentItem.first.base_path).to eq(new_base_path)
        end
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::DerivedRepresentations, :type => :request
