require "rails_helper"

RSpec.describe Edition do
  subject { build(:edition) }

  describe ".renderable_content" do
    let!(:guide) { create(:edition, schema_name: "nonexistent-schema") }
    let!(:redirect) { create(:redirect_edition) }
    let!(:gone) { create(:gone_edition) }

    it "returns editions that do not have a schema_name of 'redirect' or 'gone'" do
      expect(described_class.renderable_content).to eq [guide]
    end
  end

  describe "validations" do
    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a document" do
      subject.document = nil
      expect(subject).to be_invalid
    end

    it "requires a schema_name" do
      subject.schema_name = ""
      expect(subject).to be_invalid
    end

    it "requires a publishing_app" do
      subject.publishing_app = ""
      expect(subject).to be_invalid
    end

    it "where auth_bypass_ids has an array with a uuids" do
      subject.auth_bypass_ids = [SecureRandom.uuid, SecureRandom.uuid]
      expect(subject).to be_valid
    end

    it "where auth_bypass_ids has an array with non uuids" do
      subject.auth_bypass_ids = ["not-a-uuid"]
      expect(subject).to be_invalid
    end

    it "where users has an array with an integer" do
      subject.auth_bypass_ids = [123]
      expect(subject).to be_invalid
    end

    context "when the edition is 'redirect' but has routes" do
      before do
        subject.document_type = "redirect"
        subject.routes = [{ path: subject.base_path + "/test", type: :exact }]
        subject.redirects = [{ path: subject.base_path, type: :exact, destination: "/dest" }]
      end

      it "should not be valid" do
        expect(subject).to be_invalid
        expect(subject.errors[:routes]).to_not be_empty
      end
    end

    context "when the edition is 'renderable'" do
      before do
        subject.document_type = "nonexistent-schema"
      end

      it "requires a title" do
        subject.title = ""
        expect(subject).to be_invalid
      end

      it "requires a rendering_app" do
        subject.rendering_app = nil
        expect(subject).to be_invalid
      end

      it "requires a rendering_app to have a valid hostname" do
        subject.rendering_app = ""
        expect(subject).to be_invalid
      end

      it "requires that the rendering_app is a valid DNS hostname" do
        %w[word alpha12numeric dashed-item].each do |value|
          subject.rendering_app = value
          expect(subject).to be_valid
        end

        ["no spaces", "puncutation!", "mixedCASE"].each do |value|
          subject.rendering_app = value
          expect(subject).to be_invalid
          expect(subject.errors[:rendering_app].size).to eq(1)
        end
      end
    end

    context "when the edition is not 'renderable'" do
      subject { build(:redirect_edition) }

      it "does not require a title" do
        subject.title = ""
        expect(subject).to be_valid
      end

      it "does not require a rendering_app" do
        subject.rendering_app = ""
        expect(subject).to be_valid
      end
    end

    context "when the edition is optionally 'renderable'" do
      subject { build(:edition, document_type: "contact") }

      it "does not require a rendering_app" do
        subject.rendering_app = nil
        expect(subject).to be_valid
      end
    end

    context "base_path" do
      it "should be an absolute path" do
        subject.base_path = "invalid//absolute/path/"
        expect(subject).to be_invalid
        expect(subject.errors[:base_path].size).to eq(1)
      end
    end

    context "when another edition has the same base path" do
      before { create(:draft_edition, base_path: "/foo") }

      let(:edition) do
        build(:edition, base_path: "/foo", state: "draft")
      end
      subject { edition }

      it { is_expected.to be_invalid }

      context "and the state is different" do
        before { edition.state = "published" }

        it { is_expected.to be_valid }
      end
    end

    context "phase" do
      it "defaults to live" do
        expect(described_class.new.phase).to eq("live")
      end

      %w[alpha beta live].each do |phase|
        it "is valid with #{phase} phase" do
          subject.phase = phase
          expect(subject).to be_valid
        end
      end

      it "is invalid without a phase" do
        subject.phase = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:phase].size).to eq(1)
      end

      it "is invalid with any other phase" do
        subject.phase = "not-a-correct-phase"
        expect(subject).to_not be_valid
      end
    end

    context "when the state conflicts with another instance of this edition" do
      subject { edition }
      let(:existing_edition) do
        create(:draft_edition, user_facing_version: 2)
      end
      let(:edition) do
        build(
          :draft_edition,
          document: existing_edition.document,
          user_facing_version: 1,
        )
      end

      it { is_expected.to be_invalid }

      context "and the states are different" do
        before { edition.state = "published" }

        it { is_expected.to be_valid }
      end
    end

    context "when the user facing version conflicts with another instance of this edition" do
      subject { edition }
      let(:existing_edition) { create(:draft_edition) }
      let(:edition) do
        build(
          :draft_edition,
          document: existing_edition.document,
          user_facing_version: 1,
        )
      end

      it { is_expected.to be_invalid }
    end

    context "when the draft user_facing_version is ahead of the live one" do
      subject { edition }
      let(:existing_edition) do
        create(:live_edition, user_facing_version: 1)
      end
      let(:edition) do
        build(
          :draft_edition,
          document: existing_edition.document,
          user_facing_version: 2,
        )
      end

      it { is_expected.to be_valid }
    end

    context "when the draft user_facing_version is behind the live one" do
      subject { edition }
      let(:existing_edition) do
        create(:draft_edition, user_facing_version: 1)
      end
      let(:edition) do
        build(
          :live_edition,
          document: existing_edition.document,
          user_facing_version: 2,
        )
      end

      it { is_expected.to be_invalid }
    end

    context "when the live user_facing_version is ahead of the draft one" do
      subject { edition }
      let(:existing_edition) do
        create(:live_edition, user_facing_version: 2)
      end
      let(:edition) do
        build(
          :draft_edition,
          document: existing_edition.document,
          user_facing_version: 1,
        )
      end

      it { is_expected.to be_invalid }
    end

    context "when user_facing_version is incremented" do
      subject { edition }
      let(:edition) { create(:edition) }

      before { edition.user_facing_version += 1 }
      it { is_expected.to be_valid }
    end

    context "when user_facing_version is decremented" do
      subject { edition }
      let(:edition) { create(:edition) }

      before { edition.user_facing_version -= 1 }
      it { is_expected.to be_invalid }
    end

    describe "routes and redirects" do
      subject { edition }
      let(:edition) { build(:edition, base_path: "/vat-rates") }
      it_behaves_like RoutesAndRedirectsValidator
    end
  end

  describe "#details_for_govspeak_conversion" do
    subject do
      build(:edition, details: details)
        .details_for_govspeak_conversion
    end

    let(:html_content) { { content_type: "text/html", content: "<b>Hello</b>" } }
    let(:govspeak_content) { { content_type: "text/govspeak", content: "**Hello**" } }

    context "details has no body" do
      let(:details) { { field: "value" } }
      it { is_expected.to match(details) }
    end

    context "details doesn't have a text/govspeak content type" do
      let(:details) { { body: [html_content] } }
      it { is_expected.to match(details) }
    end

    context "details doesn't have a text/html content type" do
      let(:details) { { body: [govspeak_content] } }
      it { is_expected.to match(details) }
    end

    context "details has text/html and text/govspeak content types" do
      let(:details) { { body: [html_content, govspeak_content] } }
      it { is_expected.to match(body: [govspeak_content]) }
    end

    context "details has govspeak in multiple keys" do
      let(:details) do
        {
          key_1: [html_content, govspeak_content],
          key_2: [govspeak_content, html_content],
          key_3: html_content,
        }
      end
      let(:expected_result) do
        {
          key_1: [govspeak_content],
          key_2: [govspeak_content],
          key_3: html_content,
        }
      end
      it { is_expected.to match(expected_result) }
    end
  end

  it_behaves_like WellFormedContentTypesValidator

  context "#publish" do
    it "changes the content_store to live" do
      expect { subject.publish }.to change { subject.content_store }.from("draft").to("live")
    end

    it "changes the state to published" do
      expect { subject.publish }.to change { subject.state }.from("draft").to("published")
    end
  end

  context "#supersede" do
    it "changes the content_store to nil" do
      expect { subject.supersede }.to change { subject.content_store }.from("draft").to(nil)
    end

    it "changes the state to superseded" do
      expect { subject.supersede }.to change { subject.state }.from("draft").to("superseded")
    end
  end

  context "#unpublish" do
    subject { build(:live_edition) }

    it "changes the content_store to nil when type substitute" do
      expect { subject.unpublish(type: "substitute") }.to change { subject.content_store }.from("live").to(nil)
    end

    it "leaves the content_store as live with a type of anything else" do
      expect { subject.unpublish(type: "gone") }.to_not(change { subject.content_store })
    end

    it "changes the state to unpublished" do
      expect { subject.unpublish(type: "substitute") }.to change { subject.state }.from("published").to("unpublished")
    end
  end
end
