require 'rails_helper'

RSpec.describe DataHygiene::DuplicateContentItem::StateForLocale do
  let(:content_id_a) { SecureRandom.uuid }
  let(:content_id_b) { SecureRandom.uuid }

  def create_content_item(options = {})
    @user_facing_version ||= 0
    @user_facing_version += 1

    factory_options = {
      content_id: content_id_a,
      locale: "en",
      user_facing_version: @user_facing_version
    }.merge(options.except(:state, :locale))
    content_item = FactoryGirl.create(:superseded_content_item, factory_options)

    update = {}
    update[:state] = options[:state] if options[:state]
    update[:locale] = options[:locale] if options[:locale]
    content_item.update_columns(update) unless update.empty?

    content_item
  end

  def duplicates_row(content_id, locale, content_store, content_items)
    content_items_entry = content_items.map do |item|
      hash_including(content_item_id: item.id)
    end

    {
      content_id: content_id,
      locale: locale,
      state_content_store: content_store,
      content_items: array_including(content_items_entry),
    }
  end

  describe "#has_duplicates?" do
    subject { described_class.new.has_duplicates? }

    context "when there are no duplicates" do
      before do
        %w(draft published).each do |state|
          create_content_item(state: state)
        end
      end

      it { is_expected.to be false }
    end

    context "when there are duplicates" do
      before do
        2.times { create_content_item(state: "published") }
      end

      it { is_expected.to be true }
    end
  end

  describe "#number_of_duplicates" do
    subject { described_class.new.number_of_duplicates }

    context "when there are no duplicates" do
      it { is_expected.to be 0 }
    end

    context "when there is a duplicate" do
      before do
        2.times { create_content_item(state: "published") }
      end

      it { is_expected.to be 1 }
    end
  end

  describe "#results" do
    subject { described_class.new.results }

    let(:no_matches) do
      {
        distinct_content_ids: 0,
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

    context "when there are different states for a single content_id and locale" do
      context "when items are 'superseded'" do
        before do
          3.times { create_content_item(state: "superseded") }
        end

        it { is_expected.to match(no_matches) }
      end

      context "when items are 'published' or 'unpublished'" do
        let!(:content_items) do
          [
            create_content_item(state: "published"),
            create_content_item(state: "unpublished"),
          ]
        end

        let(:matches) do
          {
            distinct_content_ids: 1,
            content_ids: [content_id_a],
            distinct_content_item_ids: 2,
            content_item_ids: array_including(content_items.map(&:id)),
            number_of_duplicates: 1,
            duplicates: [
              duplicates_row(content_id_a, "en", "live", content_items)
            ]
          }
        end

        it { is_expected.to match(matches) }
      end

      context "when items are 'draft'" do
        let!(:drafts) do
          4.times.map { create_content_item(state: "draft") }
        end

        let(:matches) do
          {
            distinct_content_ids: 1,
            content_ids: [content_id_a],
            distinct_content_item_ids: 4,
            content_item_ids: array_including(drafts.map(&:id)),
            number_of_duplicates: 1,
            duplicates: [
              duplicates_row(content_id_a, "en", "draft", drafts)
            ]
          }
        end

        it { is_expected.to match(matches) }
      end
    end

    context "when there are different states for a single content_id and different locale" do
      context "when all items are 'draft'" do
        before do
          %w(en fr).each do |locale|
            create_content_item(state: "draft", locale: locale)
          end
        end

        it { is_expected.to match(no_matches) }
      end

      context "when all items are 'published' or 'unpublished'" do
        before do
          create_content_item(state: "published", locale: "en")
          create_content_item(state: "unpublished", locale: "fr")
        end

        it { is_expected.to match(no_matches) }
      end
    end

    context "when multiple content items have conflicts" do
      let!(:dupes_a_draft) do
        2.times.map { create_content_item(content_id: content_id_a, state: "draft") }
      end

      let!(:dupes_a_live) do
        [
          create_content_item(content_id: content_id_a, state: "published"),
          create_content_item(content_id: content_id_a, state: "unpublished"),
        ]
      end

      let!(:dupes_b_fr) do
        2.times.map do
          create_content_item(
            content_id: content_id_b, state: "published", locale: "fr"
          )
        end
      end

      let!(:dupes_b_en) do
        2.times.map do
          create_content_item(
            content_id: content_id_b, state: "published", locale: "en"
          )
        end
      end

      let(:matches) do
        {
          distinct_content_ids: 2,
          content_ids: array_including(content_id_a, content_id_b),
          distinct_content_item_ids: 8,
          content_item_ids: array_including(
            (dupes_a_draft + dupes_a_live + dupes_b_fr + dupes_b_en).map(&:id)
          ),
          number_of_duplicates: 4,
          duplicates: array_including(
            duplicates_row(content_id_a, "en", "draft", dupes_a_draft),
            duplicates_row(content_id_a, "en", "live", dupes_a_live),
            duplicates_row(content_id_b, "fr", "live", dupes_b_fr),
            duplicates_row(content_id_b, "en", "live", dupes_b_en)
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
        expect(Airbrake).to_not receive(:notify)
        instance.log
      end
    end

    context "when there are duplicates" do
      before do
        2.times { create_content_item(state: "published") }
      end

      it "logs to airbrake" do
        expected_error = DataHygiene::DuplicateContentItem::DuplicateStateForLocaleError
        expect(Airbrake).to receive(:notify)
          .with(an_instance_of(expected_error), parameters: instance.results)
        instance.log
      end
    end
  end
end
