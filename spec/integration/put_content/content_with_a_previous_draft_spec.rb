require "rails_helper"

RSpec.describe "PUT /v2/content when the payload is for an already drafted edition" do
  include_context "PutContent call"

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  let(:document) do
    FactoryGirl.create(:document, content_id: content_id, stale_lock_version: 1)
  end
  let!(:previously_drafted_item) do
    FactoryGirl.create(:draft_edition,
      document: document,
      base_path: base_path,
      title: "Old Title",
      publishing_app: "publisher",
    )
  end

  it "updates the edition" do
    put "/v2/content/#{content_id}", params: payload.to_json
    previously_drafted_item.reload

    expect(previously_drafted_item.title).to eq("Some Title")
  end

  it "keeps the content_store as draft" do
    put "/v2/content/#{content_id}", params: payload.to_json
    previously_drafted_item.reload

    expect(previously_drafted_item.content_store).to eq("draft")
  end

  it "allows the setting of first_published_at" do
    explicit_first_published = DateTime.new(2016, 05, 23, 1, 1, 1).rfc3339
    payload[:first_published_at] = explicit_first_published

    put "/v2/content/#{content_id}", params: payload.to_json

    expect(previously_drafted_item.reload.first_published_at)
      .to eq(explicit_first_published)
  end

  it "keeps the first_published_at timestamp if not set in payload" do
    first_published_at = 1.year.ago
    previously_drafted_item.update_attributes(first_published_at: first_published_at)

    put "/v2/content/#{content_id}", params: payload.to_json
    previously_drafted_item.reload

    expect(previously_drafted_item.first_published_at).to be_present
    expect(previously_drafted_item.first_published_at.iso8601).to eq(first_published_at.iso8601)
  end

  it "does not increment the user-facing version for the edition" do
    put "/v2/content/#{content_id}", params: payload.to_json
    previously_drafted_item.reload

    expect(previously_drafted_item.user_facing_version).to eq(1)
  end

  it "increments the lock version for the document" do
    put "/v2/content/#{content_id}", params: payload.to_json

    expect(document.reload.stale_lock_version).to eq(2)
  end

  context "when the base path has changed" do
    before do
      previously_drafted_item.update_attributes!(
        routes: [{ path: "/old-path", type: "exact" }, { path: "/old-path.atom", type: "exact" }],
        base_path: "/old-path",
      )
    end

    it "updates the location's base path" do
      put "/v2/content/#{content_id}", params: payload.to_json
      previously_drafted_item.reload

      expect(previously_drafted_item.base_path).to eq("/vat-rates")
    end

    it "creates a redirect" do
      put "/v2/content/#{content_id}", params: payload.to_json

      redirect = Edition.find_by(
        base_path: "/old-path",
        state: "draft",
      )

      expect(redirect).to be_present
      expect(redirect.schema_name).to eq("redirect")
      expect(redirect.publishing_app).to eq("publisher")

      expect(redirect.redirects).to eq([
        {
          path: "/old-path",
          type: "exact",
          destination: base_path
        }, {
          path: "/old-path.atom",
          type: "exact",
          destination: "#{base_path}.atom"
        }
      ])
    end

    it "sends a create request to the draft content store for the redirect" do
      expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).twice

      put "/v2/content/#{content_id}", params: payload.to_json
    end

    context "when the locale differs from the existing draft edition" do
      before do
        payload.merge!(locale: "fr", title: "French Title")
      end

      it "creates a separate draft edition in the given locale" do
        put "/v2/content/#{content_id}", params: payload.to_json
        expect(Edition.count).to eq(2)

        edition = Edition.last
        expect(edition.title).to eq("French Title")

        expect(edition.document.locale).to eq("fr")
      end
    end

    context "when there is a draft at the new base path" do
      let!(:substitute_item) do
        FactoryGirl.create(:draft_edition,
          base_path: base_path,
          title: "Substitute Content",
          publishing_app: "publisher",
          document_type: "coming_soon",
        )
      end

      it "deletes the substitute item" do
        put "/v2/content/#{content_id}", params: payload.to_json
        expect(Edition.exists?(id: substitute_item.id)).to eq(false)
      end

      context "conflicting version" do
        before do
          previously_drafted_item.document.update!(stale_lock_version: 2)
          payload.merge!(previous_version: 1)
        end

        it "doesn't delete the substitute item" do
          put "/v2/content/#{content_id}", params: payload.to_json

          expect(response.status).to eq(409)
          expect(response.body).to match(/lock-version conflict/)
          expect(Edition.exists?(id: substitute_item.id)).to eq(true)
        end
      end
    end
  end

  context "with a 'previous_version' which does not match the current lock_version of the draft item" do
    before do
      previously_drafted_item.document.update!(stale_lock_version: 2)
      payload.merge!(previous_version: 1)
    end

    it "raises an error" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect(response.status).to eq(409)
      expect(response.body).to match(/lock-version conflict/)
    end
  end

  context "when some of the attributes are not provided in the payload" do
    before do
      payload.delete(:redirects)
      payload.delete(:phase)
      payload.delete(:locale)
    end

    it "resets those attributes to their defaults from the database" do
      put "/v2/content/#{content_id}", params: payload.to_json
      edition = Edition.last

      expect(edition.redirects).to eq([])
      expect(edition.phase).to eq("live")
      expect(edition.document.locale).to eq("en")
    end
  end

  context "when the previous draft has an access limit" do
    let!(:access_limit) do
      FactoryGirl.create(:access_limit, edition: previously_drafted_item, users: ["old-user"])
    end

    context "when the params includes an access limit" do
      let(:auth_bypass_id) { SecureRandom.uuid }
      before do
        payload.merge!(
          access_limited: {
            users: ["new-user"],
            auth_bypass_ids: [auth_bypass_id],
          }
        )
      end

      it "updates the existing access limit" do
        put "/v2/content/#{content_id}", params: payload.to_json
        access_limit.reload

        expect(access_limit.users).to eq(["new-user"])
        expect(access_limit.auth_bypass_ids).to eq([auth_bypass_id])
      end
    end

    context "when the params does not include an access limit" do
      it "deletes the existing access limit" do
        expect {
          put "/v2/content/#{content_id}", params: payload.to_json
        }.to change(AccessLimit, :count).by(-1)
      end
    end
  end

  context "when the previously drafted item does not have an access limit" do
    context "when the params includes an access limit" do
      let(:auth_bypass_id) { SecureRandom.uuid }
      before do
        payload.merge!(
          access_limited: {
            users: ["new-user"],
            auth_bypass_ids: [auth_bypass_id],
          }
        )
      end

      it "creates a new access limit" do
        expect {
          put "/v2/content/#{content_id}", params: payload.to_json
        }.to change(AccessLimit, :count).by(1)

        access_limit = AccessLimit.find_by!(edition: previously_drafted_item)
        expect(access_limit.users).to eq(["new-user"])
        expect(access_limit.auth_bypass_ids).to eq([auth_bypass_id])
      end
    end
  end
end
