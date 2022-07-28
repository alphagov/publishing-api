RSpec.describe Queries::GetContent do
  let(:content_id) { SecureRandom.uuid }
  let(:document) { create(:document, content_id:) }
  let(:fr_document) { create(:document, content_id:, locale: "fr") }

  context "when no edition exists for the content_id" do
    it "raises a command error" do
      expect {
        subject.call(content_id)
      }.to raise_error(CommandError, /with content_id: #{content_id}/)
    end
  end

  context "when a edition exists for the content_id" do
    let(:incorrect_version) { 2 }
    let(:incorrect_locale) { "fr" }

    before do
      create(
        :edition,
        document:,
        base_path: "/vat-rates",
        user_facing_version: 1,
      )
    end

    it "presents the edition" do
      result = subject.call(content_id)

      expect(result).to include(
        "content_id" => content_id,
        "base_path" => "/vat-rates",
        "locale" => "en",
        "lock_version" => 1,
      )
    end

    context "when a edition for the requested version does not exist" do
      it "raises a command error" do
        expect {
          subject.call(content_id, version: incorrect_version)
        }.to raise_error(CommandError, /version: #{incorrect_version} for document/)
      end
    end

    context "when a edition for the requested locale does not exist" do
      it "raises a command error" do
        expect {
          subject.call(content_id, incorrect_locale)
        }.to raise_error(CommandError, /locale: #{incorrect_locale} for document/)
      end
    end

    context "when a edition for the requested version and locale does not exist" do
      it "raises a command error" do
        expect {
          subject.call(content_id, incorrect_locale, version: incorrect_version)
        }.to raise_error(CommandError, /locale: #{incorrect_locale} and version: #{incorrect_version}/)
      end
    end
  end

  context "when a draft and a live edition exists for the content_id" do
    before do
      create(
        :draft_edition,
        document:,
        title: "Draft Title",
        user_facing_version: 2,
      )

      create(
        :live_edition,
        document:,
        title: "Live Title",
        user_facing_version: 1,
      )
    end

    it "presents the draft edition" do
      result = subject.call(content_id)
      expect(result.fetch("title")).to eq("Draft Title")
    end
  end

  context "when editions exist in non-draft, non-live states" do
    before do
      create(
        :superseded_edition,
        document:,
        user_facing_version: 1,
        title: "Older Title",
      )

      create(
        :superseded_edition,
        document:,
        user_facing_version: 2,
        title: "Newer Title",
      )
    end

    it "includes these editions" do
      result = subject.call(content_id)
      expect(result.fetch("title")).to eq("Newer Title")
    end
  end

  context "when editions exist in multiple locales" do
    before do
      create(
        :edition,
        document: fr_document,
        user_facing_version: 2,
        title: "French Title",
      )

      create(
        :edition,
        document:,
        user_facing_version: 1,
        title: "English Title",
      )
    end

    it "returns the english edition by default" do
      result = subject.call(content_id)
      expect(result.fetch("title")).to eq("English Title")
    end

    it "filters editions by the specified locale" do
      result = subject.call(content_id, "fr")
      expect(result.fetch("title")).to eq("French Title")
    end
  end

  describe "requesting specific versions" do
    before do
      create(
        :superseded_edition,
        document:,
        user_facing_version: 1,
      )

      create(
        :live_edition,
        document:,
        user_facing_version: 2,
      )
    end

    it "returns specific versions if provided" do
      result = subject.call(content_id, version: 1)
      expect(result.fetch("publication_state")).to eq("superseded")

      result = subject.call(content_id, version: 2)
      expect(result.fetch("publication_state")).to eq("published")
    end

    it "returns the most recent if version isn't given" do
      result = subject.call(content_id)
      expect(result.fetch("publication_state")).to eq("published")
    end
  end
end
