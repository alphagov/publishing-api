RSpec.describe "PUT /v2/content when the payload is for an already drafted edition" do
  include_context "PutContent call"

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
    Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0))
  end

  after do
    Timecop.return
  end

  let(:document) do
    create(:document, content_id: content_id, stale_lock_version: 1)
  end
  let!(:previously_drafted_item) do
    create(
      :draft_edition,
      document: document,
      base_path: base_path,
      title: "Old Title",
      publishing_app: "publisher",
      update_type: "major",
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

  it "sets publishing_api_last_edited_at to current time" do
    put "/v2/content/#{content_id}", params: payload.to_json
    previously_drafted_item.reload

    expect(previously_drafted_item.publishing_api_last_edited_at).to eq(Time.zone.now)
  end

  it "sets last_edited_at to current time" do
    put "/v2/content/#{content_id}", params: payload.to_json
    previously_drafted_item.reload

    expect(previously_drafted_item.last_edited_at).to eq(Time.zone.now)
  end

  context "when public_updated_at is in the payload" do
    let(:public_updated_at) { Time.zone.now }
    before do
      payload[:public_updated_at] = public_updated_at
    end

    it "allows the setting of public_updated_at" do
      put "/v2/content/#{content_id}", params: payload.to_json
      previously_drafted_item.reload

      expect(previously_drafted_item.public_updated_at)
        .to eq(public_updated_at)
    end
  end

  context "when first_published_at is in the payload" do
    it "allows the setting of first_published_at and publisher_first_published_at" do
      explicit_first_published = Time.zone.parse("2016-5-23 1:00").rfc3339
      payload[:first_published_at] = explicit_first_published

      put "/v2/content/#{content_id}", params: payload.to_json

      expect(previously_drafted_item.reload.first_published_at)
        .to eq(explicit_first_published)
    end
  end

  it "has a publishing_api_first_published_at of nil" do
    put "/v2/content/#{content_id}", params: payload.to_json
    expect(previously_drafted_item.reload.publishing_api_first_published_at)
      .to be_nil
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
      previously_drafted_item.update!(
        routes: [{ path: "/old-path", type: "exact" }, { path: "/old-path.atom", type: "exact" }],
        base_path: "/old-path",
      )
    end

    it "updates the location's base path" do
      put "/v2/content/#{content_id}", params: payload.to_json
      previously_drafted_item.reload

      expect(previously_drafted_item.base_path).to eq("/vat-rates")
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
        create(
          :draft_edition,
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
          payload.merge!(previous_version: "1")
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
      payload.merge!(previous_version: "1")
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
      create(:access_limit, edition: previously_drafted_item, users: %w[old-user])
    end

    context "when the params includes an access limit" do
      let(:auth_bypass_id) { SecureRandom.uuid }
      before do
        payload.merge!(
          access_limited: {
            users: %w[new-user],
          },
        )
      end

      it "updates the existing access limit" do
        put "/v2/content/#{content_id}", params: payload.to_json
        access_limit.reload

        expect(access_limit.users).to eq(%w[new-user])
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

  context "when the auth_bypass_ids has been updated" do
    it "updates the edition with auth_bypass_ids params" do
      payload.merge!(auth_bypass_ids: [SecureRandom.uuid])

      put "/v2/content/#{content_id}", params: payload.to_json
      expect(Edition.last.auth_bypass_ids).to eq(payload[:auth_bypass_ids])
    end
  end

  context "when the previously drafted item does not have an access limit" do
    context "when the params includes an access limit" do
      before do
        payload.merge!(
          access_limited: {
            users: %w[new-user],
          },
        )
      end

      it "creates a new access limit" do
        expect {
          put "/v2/content/#{content_id}", params: payload.to_json
        }.to change(AccessLimit, :count).by(1)

        access_limit = AccessLimit.find_by!(edition: previously_drafted_item)
        expect(access_limit.users).to eq(%w[new-user])
      end
    end
  end

  context "when the change note has been updated" do
    let(:change_note) { "updated note" }

    it "updates the change note" do
      expect { put "/v2/content/#{content_id}", params: payload.to_json }
        .to change { previously_drafted_item.change_note.reload.note }
        .from("note").to("updated note")
    end
  end

  context "when the change note has been removed" do
    before do
      payload.delete(:change_note)
      payload[:update_type] = "minor"
    end

    it "removes the change note" do
      expect { put "/v2/content/#{content_id}", params: payload.to_json }
        .to change(ChangeNote, :count).by(-1)
    end
  end
end
