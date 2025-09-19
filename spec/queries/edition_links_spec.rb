RSpec.describe Queries::EditionLinks do
  let(:content_id) { SecureRandom.uuid }

  describe ".from" do
    subject(:result) do
      described_class.from(content_id, locale: "en", with_drafts: false)
    end

    context "when there are multiple links of the same type" do
      let(:link_type) { "organisations" }

      context "and they have different positions" do
        let(:edition) { create(:live_edition, document: create(:document, content_id:)) }
        let!(:first_link) { create(:link, link_type:, edition:, position: 1) }
        let!(:third_link) { create(:link, link_type:, edition:, position: 3) }
        let!(:second_link) { create(:link, link_type:, edition:, position: 2) }

        it "orders by position" do
          expect(result[:organisations].map { _1[:content_id] }).to eq [
            first_link.target_content_id,
            second_link.target_content_id,
            third_link.target_content_id,
          ]
        end
      end
    end
  end

  describe ".to" do
    subject(:result) do
      described_class.to(content_id, locale: "en", with_drafts: false)
    end

    context "when there are multiple links of the same type" do
      let(:link_type) { "organisations" }

      context "and they have different positions" do
        let!(:first_link) do
          create(
            :link,
            edition: create(:live_edition),
            link_type:,
            target_content_id: content_id,
            position: 1,
          )
        end
        let!(:third_link) do
          create(
            :link,
            edition: create(:live_edition),
            link_type:,
            target_content_id: content_id,
            position: 3,
          )
        end
        let!(:second_link) do
          create(
            :link,
            edition: create(:live_edition),
            link_type:,
            target_content_id: content_id,
            position: 2,
          )
        end

        it "orders by position" do
          expect(result[:organisations].map { _1[:content_id] }).to eq [
            first_link.edition.content_id,
            second_link.edition.content_id,
            third_link.edition.content_id,
          ]
        end
      end
    end
  end
end
