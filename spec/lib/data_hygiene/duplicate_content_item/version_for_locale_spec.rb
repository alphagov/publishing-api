require 'rails_helper'

RSpec.describe DataHygiene::DuplicateContentItem::VersionForLocale do
  let(:content_id_a) { SecureRandom.uuid }
  let(:content_id_b) { SecureRandom.uuid }

  def create_content_item(options = {})
    @user_facing_version ||= 0
    @user_facing_version += 1

    factory_options = {
      content_id: content_id_a,
      locale: "en",
      user_facing_version: @user_facing_version
    }.merge(options.except(:user_facing_version, :locale))
    content_item = FactoryGirl.create(:superseded_content_item, factory_options)

    if options[:user_facing_version]
      UserFacingVersion.find_by(content_item: content_item)
        .update_attribute(:number, options[:user_facing_version])
    end

    if options[:locale]
      Translation.find_by(content_item: content_item)
        .update_attribute(:locale, options[:locale])
    end

    content_item
  end

  def duplicates_row(content_id, locale, user_facing_version, content_items)
    content_items_entry = content_items.map do |item|
      hash_including(content_item_id: item.id)
    end

    {
      content_id: content_id,
      locale: locale,
      user_facing_version: user_facing_version,
      content_items: array_including(content_items_entry),
    }
  end

  describe "#has_duplicates?" do
    subject { described_class.new.has_duplicates? }

    context "when there are no duplicates" do
      before do
        [1, 2].each { |version| create_content_item(user_facing_version: version) }
      end

      it { is_expected.to be false }
    end

    context "when there are duplicates" do
      before do
        2.times { create_content_item(user_facing_version: 1) }
      end

      it { is_expected.to be true }
    end
  end

  describe "number_of_duplicates" do
    subject { described_class.new.number_of_duplicates }

    context "when there are no duplicates" do
      it { is_expected.to be 0 }
    end

    context "when there is a duplicate" do
      before do
        2.times { create_content_item(user_facing_version: 1) }
      end

      it { is_expected.to be 1 }
    end
  end

  describe "#results" do
    subject { described_class.new.results }
    let(:no_matches) do
      {
        distinct_content_items: 0,
        content_ids: [],
        distinct_content_item_ids: 0,
        content_item_ids: [],
        number_of_duplicates: 0,
        duplicates: []
      }
    end

    context "when there are no duplicates" do
      it { is_expected.to match(no_matches) }
    end

    context "when there are conflicts for a single content_id" do
      let!(:conflicts) do
        3.times.map { create_content_item(user_facing_version: 5) }
      end

      let(:matches) do
        {
          distinct_content_items: 1,
          content_ids: [content_id_a],
          distinct_content_item_ids: 3,
          content_item_ids: conflicts.reverse.map(&:id),
          number_of_duplicates: 1,
          duplicates: [
            duplicates_row(content_id_a, "en", 5, conflicts)
          ]
        }
      end

      it { is_expected.to match(matches) }
    end

    context "when a single content_id has multiple instances of the same version with different locales" do
      before do
        %w(en fr de).each do |locale|
          create_content_item(user_facing_version: 5, locale: locale)
        end
      end

      it { is_expected.to match(no_matches) }
    end

    context "when multiple content items have conflicts" do
      let!(:dupes_a) do
        3.times.map do
          create_content_item(content_id: content_id_a, user_facing_version: 5, locale: "en")
        end
      end

      let!(:dupes_b) do
        2.times.map do
          create_content_item(content_id: content_id_b, user_facing_version: 4, locale: "fr")
        end
      end

      before do
        create_content_item(content_id: content_id_b, user_facing_version: 3, locale: "en")
      end

      let(:matches) do
        {
          distinct_content_items: 2,
          content_ids: array_including(content_id_a, content_id_b),
          distinct_content_item_ids: 5,
          content_item_ids: array_including((dupes_a + dupes_b).map(&:id)),
          number_of_duplicates: 2,
          duplicates: array_including(
            duplicates_row(content_id_a, "en", 5, dupes_a),
            duplicates_row(content_id_b, "fr", 4, dupes_b),
          )
        }
      end

      it { is_expected.to match(matches) }
    end
  end

  describe "#log" do
    subject(:instance) { described_class.new }

    context "when there are no duplicates" do
      it "doesn't log to airbrake" do
        expect(Airbrake).to_not receive(:notify_or_ignore)
        instance.log
      end
    end

    context "when there are duplicates" do
      before do
        2.times { create_content_item(user_facing_version: 3) }
      end

      it "logs to airbrake" do
        expected_error = DataHygiene::DuplicateContentItem::DuplicateVersionForLocaleError
        expect(Airbrake).to receive(:notify_or_ignore)
          .with(an_instance_of(expected_error), parameters: instance.results)
        instance.log
      end
    end
  end
end
