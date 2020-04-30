require "rails_helper"

RSpec.describe Queries::ContentDependencies do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }
  let(:locale) { :en }
  let(:content_stores) { %w[live] }

  describe "#call" do
    subject do
      described_class.new(
        content_id: content_id,
        locale: locale,
        content_stores: content_stores,
      ).call
    end

    context "when there are no links or translations" do
      it { is_expected.to be_empty }
    end

    context "when there are translations of the edition" do
      before do
        create_edition(content_id, "/a", locale: "en")
        create_edition(content_id, "/a.fr", locale: "fr")
        create_edition(content_id, "/a.es", locale: "es")
      end

      context "and we specify locale as en" do
        let(:locale) { "en" }
        let(:translations) do
          [
            [content_id, "fr"],
            [content_id, "es"],
          ]
        end

        it { is_expected.to match_array(translations) }
      end

      context "and we specify locale as es" do
        let(:locale) { "es" }
        let(:translations) do
          [
            [content_id, "en"],
            [content_id, "fr"],
          ]
        end

        it { is_expected.to match_array(translations) }
      end

      context "and we don't specify a locale" do
        let(:locale) { nil }
        let(:translations) do
          [
            [content_id, "en"],
            [content_id, "fr"],
            [content_id, "es"],
          ]
        end

        it { is_expected.to match_array(translations) }
      end
    end

    context "when there are draft translations of the edition" do
      before do
        create_edition(content_id, "/a", locale: "en")
        create_edition(content_id, "/a.cy", factory: :draft_edition, locale: "cy")
      end

      let(:locale) { "en" }
      let(:content_stores) { %w[live] }

      it { is_expected.to be_empty }

      context "but we requested drafts in content_stores" do
        let(:content_stores) { %w[draft live] }
        let(:translations) do
          [
            [content_id, "cy"],
          ]
        end

        it { is_expected.to match_array(translations) }
      end
    end

    context "when items link to this edition" do
      before do
        create_edition(link_1_content_id, "/link-1", locale: "en")
        create_edition(link_2_content_id, "/link-2", locale: "en")
        create_link(link_1_content_id, content_id, "organisation")
        create_link(link_2_content_id, content_id, "organisation")
      end

      let(:link_1_content_id) { SecureRandom.uuid }
      let(:link_2_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          [link_1_content_id, "en"],
          [link_2_content_id, "en"],
        ]
      end

      it { is_expected.to match_array(links) }
    end

    context "when items in different translations link to this edition" do
      before do
        create_edition(link_content_id, "/link", locale: "en")
        create_edition(link_content_id, "/link.cy", locale: "cy")
        create_link(link_content_id, content_id, "organisation")
      end

      let(:link_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          [link_content_id, "en"],
          [link_content_id, "cy"],
        ]
      end

      it { is_expected.to match_array(links) }
    end

    context "when items in different translations link to this edition" do
      before do
        create_edition(content_id, "/", locale: :en)
        create_edition(link1_content_id, "/link.fr", locale: "fr",
                                                     links_hash: { organisation: [content_id] })
        create_edition(link2_content_id, "/link.cy", locale: "cy",
                                                     links_hash: { organisation: [content_id] })
      end

      let(:link1_content_id) { SecureRandom.uuid }
      let(:link2_content_id) { SecureRandom.uuid }

      context "with a locale of cy" do
        let(:locale) { :cy }
        let(:links) do
          [
            [link2_content_id, "cy"],
            [content_id, "en"], # available translation
          ]
        end

        it { is_expected.to match_array(links) }
      end

      context "with a locale of fr" do
        let(:locale) { :fr }
        let(:links) do
          [
            [link1_content_id, "fr"],
            [content_id, "en"], # available translation
          ]
        end

        it { is_expected.to match_array(links) }
      end
    end

    context "when items in different states link to this edition" do
      before do
        create_edition(link_1_content_id, "/link")
        create_edition(link_2_content_id, "/link", factory: :draft_edition)
        create_link(link_1_content_id, content_id, "organisation")
        create_link(link_2_content_id, content_id, "organisation")
      end

      let(:link_1_content_id) { SecureRandom.uuid }
      let(:link_2_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          [link_1_content_id, "en"],
        ]
      end

      it { is_expected.to match_array(links) }

      context "and we include drafts" do
        let(:content_stores) { %w[draft live] }

        let(:links) do
          [
            [link_1_content_id, "en"],
            [link_2_content_id, "en"],
          ]
        end

        it { is_expected.to match_array(links) }
      end
    end

    context "when a graph of parent items link to this edition" do
      before do
        create_edition(great_grandparent_content_id, "/great")
        create_edition(grandparent_content_id, "/great/grand")
        create_edition(parent_content_id, "/great/grand/parent")
        create_link(parent_content_id, content_id, "parent")
        create_link(grandparent_content_id, parent_content_id, "parent")
        create_link(great_grandparent_content_id, grandparent_content_id, "parent")
      end

      let(:great_grandparent_content_id) { SecureRandom.uuid }
      let(:grandparent_content_id) { SecureRandom.uuid }
      let(:parent_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          [great_grandparent_content_id, "en"],
          [grandparent_content_id, "en"],
          [parent_content_id, "en"],
        ]
      end

      it { is_expected.to match_array(links) }
    end

    context "when this edition has a link to an item with a reverse link type" do
      before do
        create_edition(reverse_link_content_id, "/reverse")
        create_link(content_id, reverse_link_content_id, "documents")
      end

      let(:reverse_link_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          [reverse_link_content_id, "en"],
        ]
      end

      it { is_expected.to match_array(links) }

      context "and there are translations of item that links" do
        before do
          create_edition(reverse_link_content_id, "/reverse.cy", locale: "cy")
        end

        let(:links) do
          [
            [reverse_link_content_id, "en"],
            [reverse_link_content_id, "cy"],
          ]
        end

        it { is_expected.to match_array(links) }
      end
    end

    context "when this content has a link to a draft item with a reverse link type" do
      before do
        create_edition(reverse_link_content_id, "/reverse", factory: :draft_edition)
        create_link(content_id, reverse_link_content_id, "documents")
      end

      let(:reverse_link_content_id) { SecureRandom.uuid }
      let(:content_stores) { %w[live] }

      it { is_expected.to be_empty }

      context "and we allow drafts" do
        let(:content_stores) { %w[draft live] }

        let(:links) do
          [
            [reverse_link_content_id, "en"],
          ]
        end

        it { is_expected.to match_array(links) }
      end
    end
  end
end
