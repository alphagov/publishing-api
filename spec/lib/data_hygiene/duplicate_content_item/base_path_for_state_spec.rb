require 'rails_helper'

RSpec.describe DataHygiene::DuplicateContentItem::BasePathForState do
  let(:content_id_a) { SecureRandom.uuid }
  let(:content_id_b) { SecureRandom.uuid }
  let(:base_path_a) { "/item-a" }
  let(:base_path_b) { "/item-b" }

  def create_content_item(options = {})
    @user_facing_version ||= 0
    @user_facing_version += 1

    factory_options = {
      content_id: content_id_a,
      base_path: base_path_a,
      locale: "en",
      user_facing_version: @user_facing_version
    }.merge(options.except(:state, :base_path))
    content_item = FactoryGirl.create(:superseded_content_item, factory_options)

    update = {}
    update[:state] = options[:state] if options[:state]
    update[:base_path] = options[:base_path] if options[:base_path]
    content_item.update_columns(update) unless update.empty?

    content_item
  end

  def duplicates_row(base_path, content_store, content_ids, content_items)
    content_items_entry = content_items.map do |item|
      hash_including(content_item_id: item.id)
    end

    {
      base_path: base_path,
      content_store: content_store,
      content_ids: array_including(content_ids),
      content_items: array_including(content_items_entry),
    }
  end

  describe "#has_duplicates?" do
    subject { described_class.new.has_duplicates? }

    context "when there are no duplicates" do
      before do
        %w(published draft).each { |state| create_content_item(state: state) }
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

    context "when the same base_path is used by content items in the same state" do
      context "when multiple items are 'superseded'" do
        before do
          2.times { create_content_item(state: "superseded") }
        end

        it { is_expected.to match(no_matches) }
      end

      context "when an item is published and the other unpublished" do
        %w(gone withdrawn redirect vanish substitute).each do |unpublishing_type|
          context "when unpublished with a '#{unpublishing_type}' type" do
            let!(:unpublished) do
              FactoryGirl.create(
                "#{unpublishing_type}_unpublished_content_item",
                content_id: content_id_a,
                base_path: base_path_a,
                user_facing_version: 2,
              )
            end

            let!(:published) do
              create_content_item(state: "published", base_path: base_path_a)
            end

            let(:matches) do
              hash_including(content_item_ids: [published.id, unpublished.id])
            end

            if unpublishing_type == "substitute"
              it { is_expected.to match(no_matches) }
            else
              it { is_expected.to match(matches) }
            end
          end
        end
      end

      context "when there are multiple drafts" do
        let!(:drafts) do
          3.times.map { create_content_item(state: "draft") }
        end

        let(:matches) do
          {
            distinct_content_ids: 1,
            content_ids: [content_id_a],
            distinct_content_item_ids: 3,
            content_item_ids: array_including(drafts.map(&:id)),
            number_of_duplicates: 1,
            duplicates: [
              duplicates_row(base_path_a, "draft", content_id_a, drafts)
            ]
          }
        end

        it { is_expected.to match(matches) }
      end
    end

    context "when there are conflicts between content items" do
      let!(:dupes_a) do
        [
          create_content_item(
            base_path: base_path_a, content_id: content_id_a, state: "published"
          ),
          create_content_item(
            base_path: base_path_a, content_id: content_id_b, state: "published"
          ),
        ]
      end

      let!(:dupes_b) do
        2.times.map do
          create_content_item(
            base_path: base_path_b,
            content_id: content_id_b,
            state: "draft"
          )
        end
      end

      let(:matches) do
        {
          distinct_content_ids: 2,
          content_ids: array_including(content_id_a, content_id_b),
          distinct_content_item_ids: 4,
          content_item_ids: array_including((dupes_a + dupes_b).map(&:id)),
          number_of_duplicates: 2,
          duplicates: array_including(
            duplicates_row(base_path_a, "live", [content_id_a, content_id_b], dupes_a),
            duplicates_row(base_path_b, "draft", content_id_b, dupes_b)
          ),
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
        expected_error = DataHygiene::DuplicateContentItem::DuplicateBasePathForStateError
        expect(Airbrake).to receive(:notify)
          .with(an_instance_of(expected_error), parameters: instance.results)
        instance.log
      end
    end
  end
end
