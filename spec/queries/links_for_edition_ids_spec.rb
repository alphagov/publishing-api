require "rails_helper"

RSpec.describe Queries::LinksForEditionIds do
  def create_edition_link(edition, link_type)
    create(:link, edition_id: edition.id, link_set: nil, link_type: link_type)
  end

  def create_link_set_link(edition, link_type)
    link_set = LinkSet.find_or_create_by(content_id: edition.document.content_id)
    create(:link, edition_id: nil, link_set: link_set, link_type: link_type)
  end

  let(:edition) { create(:edition) }
  let(:edition_ids) { [edition.id] }

  describe "#merged_links" do
    subject(:merged_links) { described_class.new(edition_ids).merged_links }

    context "when there are no links" do
      it { is_expected.to be_empty }
    end

    context "when there are differing edition links and link set links" do
      let!(:edition_link) { create_edition_link(edition, "edition") }
      let!(:link_set_link) { create_link_set_link(edition, "link_set") }

      it "merges the links together" do
        expect(merged_links).to match(
          edition.id => {
            "edition" => [edition_link.target_content_id],
            "link_set" => [link_set_link.target_content_id],
          }
        )
      end
    end

    context "when there are the same link type for edition and link set links" do
      let!(:edition_link) { create_edition_link(edition, "same") }
      let!(:link_set_link) { create_link_set_link(edition, "same") }

      it "only returns the edition links" do
        expect(merged_links).to match(
          edition.id => { "same" => [edition_link.target_content_id] }
        )
      end
    end

    context "when an edition has multiple links of the same type" do
      let!(:link_1) { create_edition_link(edition, "same") }
      let!(:link_2) { create_edition_link(edition, "same") }

      it "returns all the links" do
        expect(merged_links).to match(
          edition.id => { "same" => [link_1.target_content_id, link_2.target_content_id] }
        )
      end
    end

    context "when there are links for multiple editions" do
      let(:edition_1) { create(:edition) }
      let(:edition_2) { create(:edition) }
      let(:edition_ids) { [edition_1.id, edition_2.id] }

      let!(:link_1) { create_edition_link(edition_1, "link") }
      let!(:link_2) { create_edition_link(edition_2, "link") }

      it "returns links for each edition" do
        expect(merged_links).to match(
          edition_1.id => { "link" => [link_1.target_content_id] },
          edition_2.id => { "link" => [link_2.target_content_id] },
        )
      end
    end
  end

  describe "#edition_links" do
    subject(:edition_links) { described_class.new(edition_ids).edition_links }

    context "when there are no links" do
      it { is_expected.to be_empty }
    end

    context "when there are edition links and link set links" do
      let!(:edition_link) { create_edition_link(edition, "edition") }
      let!(:link_set_link) { create_link_set_link(edition, "link_set") }

      it "only returns the edition links" do
        expect(edition_links).to match(
          edition.id => { "edition" => [edition_link.target_content_id] }
        )
      end
    end
  end

  describe "#link_set_links" do
    subject(:link_set_links) { described_class.new(edition_ids).link_set_links }

    context "when there are no links" do
      it { is_expected.to be_empty }
    end

    context "when there are edition links and link set links" do
      let!(:edition_link) { create_edition_link(edition, "edition") }
      let!(:link_set_link) { create_link_set_link(edition, "link_set") }

      it "only returns the link set links" do
        expect(link_set_links).to match(
          edition.id => { "link_set" => [link_set_link.target_content_id] }
        )
      end
    end
  end
end
