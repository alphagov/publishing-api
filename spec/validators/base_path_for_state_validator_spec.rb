require "rails_helper"

RSpec.describe BasePathForStateValidator do
  let(:state_name) { "draft" }
  let(:base_path) { "/vat-rates" }

  let(:content_item) do
    FactoryGirl.create(
      :content_item,
      state: state_name,
      base_path: base_path,
    )
  end
  let(:state) { State.find_by(content_item: content_item) }
  let(:location) { Location.find_by(content_item: content_item) }

  describe ".validate" do
    subject { described_class.new.validate(record) }

    context "when it's missing a content item" do
      let(:record) { Location.new }
      it { is_expected.to be_nil }
    end

    context "when there is no state object" do
      let(:record) { location }
      before { state.destroy }
      it { is_expected.to be_nil }
    end

    context "when state is nil" do
      let(:record) { state }
      before { state.name = nil }
      it { is_expected.to be_nil }
    end

    context "when there is no location object" do
      let(:record) { state }
      before { location.destroy }
      it { is_expected.to be_nil }
    end

    context "when base_path is nil" do
      let(:record) { location }
      before { location.base_path = nil }
      it { is_expected.to be_nil }
    end

    context "when there are multiple content items" do
      let(:record) { location }
      let(:validate) { subject }

      let(:conflict_content_id) { SecureRandom.uuid }
      let(:conflict_state_name) { "draft" }
      let(:conflict_base_path) { "/vat-rates-2016" }
      let(:conflict_locale) { "en" }

      let!(:conflict_content_item) do
        FactoryGirl.create(
          :content_item,
          content_id: conflict_content_id,
          state: conflict_state_name,
          base_path: conflict_base_path,
          locale: conflict_locale,
          user_facing_version: 2,
        )
      end

      before { location.base_path = conflict_base_path }

      context "when state is draft" do
        let(:state_name) { "draft" }

        context "when there is a draft at the base path" do
          let(:expected_error) do
            "base path=#{conflict_base_path} conflicts with content_id=" +
              "#{conflict_content_id} and locale=#{conflict_locale}"
          end
          before { validate }

          it "adds the error to content_item attribute" do
            expect(location.errors[:content_item]).to eq([expected_error])
          end
        end

        context "when draft and a missing locale" do
          let(:expected_error) do
            "base path=#{conflict_base_path} conflicts with content_id=" +
              conflict_content_id.to_s
          end

          before do
            Translation.find_by(content_item: conflict_content_item).destroy
            validate
          end

          it "has an error missing locale" do
            expect(location.errors[:content_item]).to eq([expected_error])
          end
        end
      end

      %w(published unpublished).each do |name|
        context "when state is #{name}" do
          let(:state_name) { name }
          let(:conflict_state_name) { "draft" }

          context "when there is a draft at the base path" do
            it { is_expected.to be_nil }
          end

          context "when there is a live item at the base path" do
            let(:conflict_state_name) { "published" }
            let(:expected_error) do
              "base path=#{conflict_base_path} conflicts with content_id=" +
                "#{conflict_content_id} and locale=#{conflict_locale}"
            end
            before { validate }

            it "adds the error to content_item attribute" do
              expect(location.errors[:content_item]).to eq([expected_error])
            end
          end
        end
      end

      context "when state is superseded" do
        let(:state_name) { "superseded" }
        it { is_expected.to be_nil }
      end
    end
  end
end
