RSpec.describe LinkExpansion::RootEditionResolver do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }

  def resolver(locale: "en", with_drafts: false, edition: nil)
    described_class.new(edition:, content_id:, locale:, with_drafts:)
  end

  it "returns nil when no edition exists for the content_id" do
    expect(resolver.edition).to be_nil
    expect(resolver.id).to be_nil
  end

  it "returns a caller-supplied edition in preference to anything in the database" do
    create_edition(content_id, "/published")
    explicit = create_edition(SecureRandom.uuid, "/explicit")

    expect(resolver(edition: explicit).edition).to equal(explicit)
  end

  describe "state fallbacks" do
    it "finds a draft edition when with_drafts is true" do
      draft = create_edition(content_id, "/draft", factory: :draft_edition)

      expect(resolver(with_drafts: true).edition.id).to eq(draft.id)
    end

    it "ignores draft editions when with_drafts is false" do
      create_edition(content_id, "/draft", factory: :draft_edition)

      expect(resolver.edition).to be_nil
    end

    it "finds a published edition" do
      published = create_edition(content_id, "/published")

      expect(resolver.edition.id).to eq(published.id)
    end

    it "falls back to a withdrawn edition when nothing is published" do
      withdrawn = create_edition(content_id, "/withdrawn", factory: :withdrawn_unpublished_edition)

      expect(resolver.edition.id).to eq(withdrawn.id)
    end
  end

  describe "locale fallbacks" do
    it "falls back to the default locale when the requested locale has no edition" do
      en = create_edition(content_id, "/en", locale: "en")

      expect(resolver(locale: "ar").edition.id).to eq(en.id)
    end

    it "prefers the requested locale when it exists" do
      create_edition(content_id, "/en", locale: "en")
      ar = create_edition(content_id, "/ar", locale: "ar")

      expect(resolver(locale: "ar").edition.id).to eq(ar.id)
    end
  end
end
