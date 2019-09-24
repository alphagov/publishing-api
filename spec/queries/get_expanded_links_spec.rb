require "rails_helper"

RSpec.describe Queries::GetExpandedLinks do
  let(:content_id) { SecureRandom.uuid }
  let(:locale) { "en" }
  let(:with_drafts) { true }
  let(:generate) { false }

  subject(:result) do
    described_class.call(
      content_id,
      locale,
      with_drafts: with_drafts,
      generate: generate,
    )
  end

  context "when there isn't a document or link set associated with the content id" do
    it "raises a command error" do
      expect { result }.to raise_error(
        CommandError,
        /could not find links for content_id: #{content_id}/i,
      )
    end
  end

  context "when generate is false" do
    context "and there are expanded links stored" do
      let(:updated_at) { Time.new("2017-07-27 16:01:01").utc }
      let(:expanded_links) do
        {
          link_type: { content_id: SecureRandom.uuid },
        }
      end

      before do
        create(:expanded_links,
               content_id: content_id,
               locale: locale,
               with_drafts: with_drafts,
               expanded_links: expanded_links,
               updated_at: updated_at)
      end

      it "returns the data from expanded links" do
        expect(result).to match(
          generated: updated_at.iso8601,
          expanded_links: expanded_links.as_json,
        )
      end
    end

    context "but there are not expanded links stored" do
      let(:link_set_lock_version) { 3 }

      before do
        create(:link_set,
               content_id: content_id,
               links_hash: {},
               stale_lock_version: link_set_lock_version)
      end

      it "generates the links" do
        Timecop.freeze do
          expect(result).to match(
            a_hash_including(
              generated: Time.now.utc.iso8601,
              expanded_links: {},
            ),
          )
        end
      end

      it "returns the lock version" do
        expect(result).to match(a_hash_including(version: link_set_lock_version))
      end
    end
  end

  context "when generate is true" do
    let(:generate) { false }
    context "and there is not a link set associated with the content id" do
      before { create(:document, content_id: content_id) }

      it "returns a version of 0" do
        expect(result).to match(a_hash_including(version: 0))
      end
    end
  end
end
