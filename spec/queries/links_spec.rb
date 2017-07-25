require "rails_helper"

RSpec.describe Queries::Links do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }

  describe ".from" do
    subject(:result) { described_class.from(content_id) }

    context "when there is not a link" do
      it { is_expected.to be {} }
    end

    context "when there is a link" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :organisations }
      before do
        create_link_set(content_id, links_hash: { link_type => [link_content_id] })
      end

      it "returns a hash" do
        expect(result).to match(
          link_type => [a_hash_including(content_id: link_content_id)]
        )
      end
    end

    describe "allowed_link_types option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :organisations }
      let(:allowed_link_types) { [link_type] }
      subject(:result) do
        described_class.from(content_id, allowed_link_types: allowed_link_types)
      end
      before do
        create_link_set(content_id, links_hash: { link_type => [link_content_id] })
      end

      context "when a link is in allowed_link_types" do
        it { is_expected.not_to be_empty }
      end

      context "when a link is not in the allowed_link_types" do
        let(:allowed_link_types) { [:different] }
        it { is_expected.to be_empty }
      end
    end

    describe "parent_content_ids option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:parent_content_id) { SecureRandom.uuid }
      let(:parent_content_ids) { [parent_content_id] }
      subject(:result) do
        described_class.from(content_id, parent_content_ids: parent_content_ids)
      end
      before do
        create_link_set(content_id, links_hash: { type: [link_content_id] })
      end

      context "when a link is in the parent_content_ids" do
        let(:link_content_id) { parent_content_id }
        it { is_expected.to be_empty }
      end

      context "when a link is not in the parent_content_ids" do
        it { is_expected.not_to be_empty }
      end
    end

    describe "next_allowed_link_types_from option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :link_type }
      let(:child_content_id) { SecureRandom.uuid }
      let(:child_link_type) { :child }

      subject(:result) do
        described_class.from(
          content_id,
          next_allowed_link_types_from: next_allowed_link_types_from,
        )
      end

      before do
        create_link_set(content_id, links_hash: { link_type => [link_content_id] })
        create_link_set(link_content_id, links_hash: { child_link_type => [child_content_id] })
      end

      context "when next_allowed_link_types_from is nil" do
        let(:next_allowed_link_types_from) { nil }
        it "has a 'has_own_links' value of nil" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, has_own_links: nil)]
          )
        end
      end

      context "when next_allowed_link_types_from matches links" do
        let(:next_allowed_link_types_from) { { link_type => [child_link_type] } }
        it "has a 'has_own_links' value of true" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, has_own_links: true)]
          )
        end
      end

      context "when next_allowed_link_types_from doesn't match links" do
        let(:next_allowed_link_types_from) { { link_type => [:different] } }
        it "has a 'has_own_links' value of false" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, has_own_links: false)]
          )
        end
      end
    end

    describe "next_allowed_link_types_to option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :link_type }
      let(:child_content_id) { SecureRandom.uuid }
      let(:child_link_type) { :reverse_child }

      subject(:result) do
        described_class.from(
          content_id,
          next_allowed_link_types_to: next_allowed_link_types_to,
        )
      end

      before do
        create_link_set(content_id, links_hash: { link_type => [link_content_id] })
        create_link_set(child_content_id, links_hash: { child_link_type => [link_content_id] })
      end

      context "when next_allowed_link_types_to is nil" do
        let(:next_allowed_link_types_to) { nil }
        it "has a 'is_linked_to' value of nil" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, is_linked_to: nil)]
          )
        end
      end

      context "when next_allowed_link_types_to matches links" do
        let(:next_allowed_link_types_to) { { link_type => [child_link_type] } }
        it "has a 'is_linked_to' value of true" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, is_linked_to: true)]
          )
        end
      end

      context "when next_allowed_link_types_to doesn't match links" do
        let(:next_allowed_link_types_to) { { link_type => [:different] } }
        it "has a 'is_linked_to' value of false" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, is_linked_to: false)]
          )
        end
      end
    end
  end

  describe ".to" do
    subject(:result) { described_class.to(content_id) }

    context "when there is not a link" do
      it { is_expected.to be {} }
    end

    context "when there is a link" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :organisations }
      before do
        create_link_set(link_content_id, links_hash: { link_type => [content_id] })
      end

      it "returns a hash" do
        expect(result).to match(
          link_type => [a_hash_including(content_id: link_content_id)]
        )
      end
    end

    describe "allowed_link_types option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :organisations }
      let(:allowed_link_types) { [link_type] }
      subject(:result) do
        described_class.to(content_id, allowed_link_types: allowed_link_types)
      end
      before do
        create_link_set(link_content_id, links_hash: { link_type => [content_id] })
      end

      context "when a link is in allowed_link_types" do
        it { is_expected.not_to be_empty }
      end

      context "when a link is not in the allowed_link_types" do
        let(:allowed_link_types) { [:different] }
        it { is_expected.to be_empty }
      end
    end

    describe "parent_content_ids option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:parent_content_id) { SecureRandom.uuid }
      let(:parent_content_ids) { [parent_content_id] }
      subject(:result) do
        described_class.to(content_id, parent_content_ids: parent_content_ids)
      end
      before do
        create_link_set(link_content_id, links_hash: { type: [content_id] })
      end

      context "when a link is in the parent_content_ids" do
        let(:link_content_id) { parent_content_id }
        it { is_expected.to be_empty }
      end

      context "when a link is not in the parent_content_ids" do
        it { is_expected.not_to be_empty }
      end
    end

    describe "next_allowed_link_types_from option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :link_type }
      let(:child_content_id) { SecureRandom.uuid }
      let(:child_link_type) { :child }

      subject(:result) do
        described_class.to(
          content_id,
          next_allowed_link_types_from: next_allowed_link_types_from,
        )
      end

      before do
        create_link_set(link_content_id, links_hash: {
          link_type => [content_id],
          child_link_type => [child_content_id],
        })
      end

      context "when next_allowed_link_types_from is nil" do
        let(:next_allowed_link_types_from) { nil }
        it "has a 'has_own_links' value of nil" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, has_own_links: nil)]
          )
        end
      end

      context "when next_allowed_link_types_from matches links" do
        let(:next_allowed_link_types_from) { { link_type => [child_link_type] } }
        it "has a 'has_own_links' value of true" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, has_own_links: true)]
          )
        end
      end

      context "when next_allowed_link_types_from doesn't match links" do
        let(:next_allowed_link_types_from) { { link_type => [:different] } }
        it "has a 'has_own_links' value of false" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, has_own_links: false)]
          )
        end
      end
    end

    describe "next_allowed_link_types_to option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :link_type }
      let(:child_content_id) { SecureRandom.uuid }
      let(:child_link_type) { :reverse_child }

      subject(:result) do
        described_class.to(
          content_id,
          next_allowed_link_types_to: next_allowed_link_types_to,
        )
      end

      before do
        create_link_set(link_content_id, links_hash: { link_type => [content_id] })
        create_link_set(child_content_id, links_hash: { child_link_type => [link_content_id] })
      end

      context "when next_allowed_link_types_to is nil" do
        let(:next_allowed_link_types_to) { nil }
        it "has a 'is_linked_to' value of nil" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, is_linked_to: nil)]
          )
        end
      end

      context "when next_allowed_link_types_to matches links" do
        let(:next_allowed_link_types_to) { { link_type => [child_link_type] } }
        it "has a 'is_linked_to' value of true" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, is_linked_to: true)]
          )
        end
      end

      context "when next_allowed_link_types_to doesn't match links" do
        let(:next_allowed_link_types_to) { { link_type => [:different] } }
        it "has a 'is_linked_to' value of false" do
          expect(result).to match(
            link_type => [a_hash_including(content_id: link_content_id, is_linked_to: false)]
          )
        end
      end
    end
  end
end
