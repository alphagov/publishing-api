require 'rails_helper'

RSpec.describe DraftContentItem do
  subject { FactoryGirl.build(:draft_content_item) }

  def set_new_attributes(item)
    item.title = "New title"
  end

  def verify_new_attributes_set
    expect(described_class.last.title).to eq("New title")
  end

  describe ".renderable_content" do
    let!(:guide) { FactoryGirl.create(:draft_content_item, format: "guide", base_path: "/foo") }
    let!(:redirect) { FactoryGirl.create(:redirect_draft_content_item, base_path: "/bar") }
    let!(:gone) { FactoryGirl.create(:gone_draft_content_item, base_path: "/baz") }

    it "returns content items that do not have a format of 'redirect' or 'gone'" do
      expect(described_class.renderable_content).to eq [guide]
    end
  end

  describe "validations" do
    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a content_id" do
      subject.content_id = nil
      expect(subject).to be_invalid
    end

    it "requires that the content_ids match between draft and live" do
      live_item = FactoryGirl.create(:live_content_item)
      draft_item = live_item.draft_content_item

      draft_item.content_id = "something else"
      expect(draft_item).to be_invalid
    end

    it "requires a format" do
      subject.format = ""
      expect(subject).to be_invalid
    end

    it "requires a publishing_app" do
      subject.publishing_app = ""
      expect(subject).to be_invalid
    end

    context "when the content item is 'renderable'" do
      before do
        subject.format = "guide"
      end

      it "requires a title" do
        subject.title = ""
        expect(subject).to be_invalid
      end

      it "requires a rendering_app" do
        subject.rendering_app = ""
        expect(subject).to be_invalid
      end

      it "requires that the rendering_app is a valid DNS hostname" do
        %w(word alpha12numeric dashed-item).each do |value|
          subject.rendering_app = value
          expect(subject).to be_valid
        end

        ['no spaces', 'puncutation!', 'mixedCASE'].each do |value|
          subject.rendering_app = value
          expect(subject).to be_invalid
          expect(subject.errors[:rendering_app].size).to eq(1)
        end
      end

      it "requires a public_updated_at" do
        subject.public_updated_at = nil
        expect(subject).to be_invalid
      end
    end

    context "when the content item is not 'renderable'" do
      subject { FactoryGirl.build(:redirect_draft_content_item) }

      it "does not require a title" do
        subject.title = ""
        expect(subject).to be_valid
      end

      it "does not require a rendering_app" do
        subject.rendering_app = ""
        expect(subject).to be_valid
      end

      it "does not require a public_updated_at" do
        subject.public_updated_at = nil
        expect(subject).to be_valid
      end
    end

    context "#base_path" do
      it "should be required" do
        subject.base_path = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:base_path].size).to eq(1)

        subject.base_path = ''
        expect(subject).not_to be_valid
        expect(subject.errors[:base_path].size).to eq(1)
      end

      it "should be an absolute path" do
        subject.base_path = 'invalid//absolute/path/'
        expect(subject).to be_invalid
        expect(subject.errors[:base_path].size).to eq(1)
      end

      it "should have a db level uniqueness constraint" do
        FactoryGirl.create(:draft_content_item, base_path: "/foo")
        subject = FactoryGirl.build(:redirect_draft_content_item, base_path: "/foo")

        expect {
          subject.save!
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'content_id' do
      it "accepts a UUID" do
        subject.content_id = "a7c48dac-f1c6-45a8-b5c1-5c407d45826f"
        expect(subject).to be_valid
      end

      it "does not accept an arbitrary string" do
        subject.content_id = "bacon"
        expect(subject).not_to be_valid
      end

      it "does not accept an empty string" do
        subject.content_id = ""
        expect(subject).not_to be_valid
      end
    end

    context 'with a route that is not below the base path' do
      before do
        subject.routes = [
          { path: subject.base_path, type: 'exact' },
          { path: '/wrong-path', type: 'exact' },
        ]
      end

      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:routes]).to eq(["must be below the base path"])
      end
    end

    context 'with an invalid type of route' do
      before do
        subject.routes= [{ path: subject.base_path, type: 'unsupported' }]
      end

      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:routes]).to eq(["are invalid"])
      end
    end

    context 'with extra keys in a route entry' do
      before do
        subject.routes = [{ path: subject.base_path, type: 'exact', foo: 'bar' }]
      end

      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:routes]).to eq(["are invalid"])
      end
    end

    context 'special cases for a redirect item' do
      before :each do
        subject.format = "redirect"
        subject.routes = []
        subject.redirects = [{ path: subject.base_path, type: "exact", destination: "/somewhere" }]
      end

      it "should not require a title" do
        subject.title = nil
        expect(subject).to be_valid
      end

      it "should not require a rendering_app" do
        subject.rendering_app = nil
        expect(subject).to be_valid
      end

      it "should be valid with a locale" do
        subject.redirects << {"path" => subject.base_path + ".cy", "type" => "exact", "destination" => "/somewhere.cy"}
        expect(subject).to be_valid
      end

      it "should be valid with a dashed locale" do
        subject.redirects << {"path" => subject.base_path + ".es-419", "type" => "exact", "destination" => "/somewhere.es-419"}
        expect(subject).to be_valid
      end

      it "should be invalid with an invalid redirect" do
        subject.redirects = [{ path: "/vat-rates", type: "fooey", destination: "/somewhere" }]
        expect(subject).not_to be_valid
        expect(subject.errors[:redirects]).to eq(["are invalid"])
      end

      it "should be invalid with extra keys in a redirect entry" do
        subject.redirects = [{ path: "/vat-rates", type: "exact", destination: "/somewhere", foo: "bar" }]
        expect(subject).not_to be_valid
        expect(subject.errors[:redirects]).to eq(["are invalid"])
      end

      it "should be invalid if given any routes" do
        subject.routes = [{ path: subject.base_path, type: "exact" }]
        expect(subject).not_to be_valid
        expect(subject.errors[:routes]).to eq(["redirect items cannot have routes"])
      end
    end

    describe 'access limiting' do
      it "validates the format of the access_limited hash" do
        content_item = build(:draft_content_item, access_limited: { bad_key: []})
        expect(content_item).not_to be_valid

        content_item = build(:draft_content_item, access_limited: { users: { other: 'stuff'}})
        expect(content_item).not_to be_valid
      end

      context 'a content item that is not access limited' do
        let!(:content_item) { create(:draft_content_item) }

        it 'is not access limited' do
          expect(content_item.access_limited?).to be(false)
        end

        it 'is viewable by all' do
          expect(content_item.viewable_by?(nil)).to be(true)
          expect(content_item.viewable_by?('a-user-uid')).to be(true)
        end
      end

      context 'an access-limited content item' do
        let!(:content_item) { create(:access_limited_draft_content_item) }
        let(:authorised_user_uid) { content_item.access_limited[:users].first }

        it 'is access limited' do
          expect(content_item.access_limited?).to be(true)
        end

        it 'is viewable by an authorised user' do
          expect(content_item.viewable_by?(authorised_user_uid)).to be(true)
        end

        it 'is not viewable by an unauthorised user' do
          expect(content_item.viewable_by?('unauthorised-user')).to be(false)
          expect(content_item.viewable_by?(nil)).to be(false)
        end
      end
    end

    context "locale" do
      it "defaults to the default I18n locale" do
        expect(described_class.new.locale).to eq(I18n.default_locale.to_s)
      end

      it "can be set as a supported I18n locale" do
        subject.locale = 'fr'
        expect(subject).to be_valid
        expect(subject.locale).to eq('fr')
      end

      it "rejects non-supported locales" do
        subject.locale = 'xyz'
        expect(subject).to_not be_valid
        expect(subject.errors[:locale].first).to eq('must be a supported locale')
      end
    end
  end

  let!(:existing) { FactoryGirl.create(:draft_content_item) }

  let(:content_id) { existing.content_id }
  let(:payload) do
    FactoryGirl.build(:draft_content_item)
    .as_json
    .symbolize_keys
    .merge(
      content_id: content_id,
      title: "New title"
    )
  end

  let(:another_payload) do
    FactoryGirl.build(:draft_content_item)
    .as_json
    .symbolize_keys
    .merge(title: "New title")
  end

  it_behaves_like Replaceable
  it_behaves_like DefaultAttributes
  it_behaves_like ImmutableBasePath
end
