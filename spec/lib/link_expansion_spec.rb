RSpec.describe LinkExpansion do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }

  describe "#links_with_content" do
    subject do
      described_class.by_content_id(content_id).links_with_content
    end

    context "no links" do
      it { is_expected.to be_empty }
      it { is_expected.to be_a(Hash) }
    end

    context "with a link" do
      let(:link) do
        create(
          :live_edition,
          title: "Expanded Link",
          base_path: "/expanded-link",
        )
      end

      let(:expected) do
        {
          related: [
            a_hash_including(title: link.title, base_path: link.base_path),
          ],
        }
      end

      before { create_link(content_id, link.document.content_id, "related") }

      it { is_expected.to match(expected) }
    end

    context "with a withdrawn link" do
      let(:link) { create(:withdrawn_unpublished_edition) }

      before { create_link(content_id, link.document.content_id, link_type) }

      context "and a parent link_type" do
        let(:link_type) { :parent }

        it { is_expected.to match(parent: [a_hash_including(withdrawn: true)]) }
      end

      context "and a related link_type" do
        let(:link_type) { :related }

        it { is_expected.to be_empty }
      end

      context "and a related_statistical_data_sets link_type" do
        let(:link_type) { :related_statistical_data_sets }

        it { is_expected.to match(related_statistical_data_sets: [a_hash_including(withdrawn: true)]) }
      end
    end

    context "with a reverse link with member expansion configured" do
      let(:collection_content_id) { SecureRandom.uuid }
      let(:first_document_content_id) { SecureRandom.uuid }
      let(:second_document_content_id) { SecureRandom.uuid }

      let!(:collection) do
        create_edition(
          collection_content_id,
          "/government/collections/example-collection",
          document_type: "document_collection",
          schema_name: "document_collection",
          title: "Example Collection",
        )
      end

      let!(:first_document) do
        create_edition(
          first_document_content_id,
          "/government/publications/first-publication",
          document_type: "policy_paper",
          schema_name: "publication",
          title: "First Publication",
        )
      end

      let!(:second_document) do
        create_edition(
          second_document_content_id,
          "/government/publications/second-publication",
          document_type: "policy_paper",
          schema_name: "publication",
          title: "Second Publication",
        )
      end

      let(:content_id) { first_document_content_id }

      before do
        create(
          :link_set,
          content_id: collection_content_id,
          links_hash: {
            documents: [
              first_document_content_id,
              second_document_content_id,
            ],
          },
        )
      end

      it "expands all member documents under the collection" do
        document_collections = subject.fetch(:document_collections)
        expect(document_collections.size).to eq(1)

        member_documents = document_collections.first.fetch(:links).fetch(:documents)
        expect(member_documents).to contain_exactly(
          a_hash_including(
            content_id: first_document_content_id,
            title: first_document.title,
            base_path: first_document.base_path,
          ),
          a_hash_including(
            content_id: second_document_content_id,
            title: second_document.title,
            base_path: second_document.base_path,
          ),
        )
      end
    end

    context "with recursive links" do
      let(:child_content_id) { SecureRandom.uuid }
      let(:grand_child_content_id) { SecureRandom.uuid }
      let!(:child) { create_edition(child_content_id, "/child") }
      let!(:grand_child) { create_edition(grand_child_content_id, "/grand-child") }

      before do
        create_link(content_id, child_content_id, "parent")
        create_link(child_content_id, grand_child_content_id, "parent")
      end

      let(:expected) do
        {
          parent: [a_hash_including(
            base_path: child.base_path,
            links: {
              parent: [a_hash_including(
                base_path: grand_child.base_path,
                links: {},
              )],
            },
          )],
        }
      end

      it { is_expected.to match(expected) }
    end
  end
end
