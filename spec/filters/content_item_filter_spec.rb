require "rails_helper"

RSpec.describe ContentItemFilter do
  let(:content_id) { "b2844cad-4140-46db-81eb-db717370fee1" }
  let(:base_path) { "/vat-rates" }

  let!(:content_item) {
    FactoryGirl.create(:content_item,
      content_id: content_id,
      base_path: base_path,
    )
  }

  let!(:oil_and_gas_content_item) {
    FactoryGirl.create(:content_item,
      content_id: content_id,
      base_path: "/oil-and-gas"
    )
  }
  let!(:french_content_item) {
    FactoryGirl.create(:content_item,
      content_id: content_id,
      locale: "fr",
      base_path: base_path,
    )
  }
  let!(:superseded_content_item) {
    FactoryGirl.create(:content_item,
      content_id: content_id,
      state: "superseded",
      base_path: base_path,
    )
  }
  let!(:new_version_content_item) {
    FactoryGirl.create(:content_item,
      content_id: content_id,
      user_facing_version: 2,
      base_path: base_path,
    )
  }

  describe ".similar_to(content_item, params = {})" do
    context "when a base path is given" do
      let(:params) { { base_path: "/oil-and-gas" } }

      it "returns a scope of the expected content items" do
        result = described_class.similar_to(content_item, params)
        expect(result.to_a).to eq([oil_and_gas_content_item])
      end
    end

    context "when a locale is given" do
      let(:params) { { locale: "fr" } }

      it "returns a scope of the expected content items" do
        result = described_class.similar_to(content_item, params)
        expect(result.to_a).to eq([french_content_item])
      end
    end

    context "when a state is given" do
      let(:params) { { state: "superseded" } }

      it "returns a scope of the expected content items" do
        result = described_class.similar_to(content_item, params)
        expect(result.to_a).to eq([superseded_content_item])
      end
    end

    context "when a user version is given" do
      let(:params) { { user_version: 2 } }

      it "returns a scope of the expected content items" do
        result = described_class.similar_to(content_item, params)
        expect(result.to_a).to eq([new_version_content_item])
      end
    end

    context "when no filter parameters are given" do
      let(:params) { {} }

      it "returns a scope of the expected content items" do
        result = described_class.similar_to(content_item, params)
        expect(result.to_a).to eq([content_item])
      end
    end

    context "when a parameter is explicitly set to nil" do
      let(:params) { { locale: "en", base_path: nil } }

      it "returns a scope of the same content item" do
        result = described_class.similar_to(content_item, params)
        expect(result.to_a).to match_array([content_item, oil_and_gas_content_item])
      end
    end
  end

  describe ".filter(locale: nil, base_path: nil, state: nil)" do
    context "when a base path is given" do
      let(:params) { { base_path: base_path } }

      it "returns a scope of the expected content items" do
        result = described_class.filter(params)
        expect(result.to_set).to match_array([
          content_item,
          french_content_item,
          superseded_content_item,
          new_version_content_item
        ])
      end
    end

    context "when a locale is given" do
      let(:params) { { locale: "en" } }

      it "returns a scope of the expected content items" do
        result = described_class.filter(params)
        expect(result.to_set).to match_array([
          content_item,
          oil_and_gas_content_item,
          superseded_content_item,
          new_version_content_item
        ])
      end
    end

    context "when a state is given" do
      let(:params) { { state: "draft" } }

      it "returns a scope of the expected content items" do
        result = described_class.filter(params)
        expect(result.to_set).to match_array([
          content_item,
          oil_and_gas_content_item,
          french_content_item,
          new_version_content_item
        ])
      end
    end

    context "when a user version is given" do
      let(:params) { { user_version: 1 } }

      it "returns a scope of the expected content items" do
        result = described_class.filter(params)
        expect(result.to_set).to match_array([
          content_item,
          oil_and_gas_content_item,
          french_content_item,
          superseded_content_item
        ])
      end
    end

    context "when no filter parameters are given" do
      let(:params) { {} }

      it "returns a scope of all content items" do
        result = described_class.filter(params)
        expect(result.to_set).to match_array(ContentItem.all.to_a)
      end
    end
  end
end
