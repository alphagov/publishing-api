RSpec.describe ExpansionRules::LinkExpansion do
  describe "#valid_link_types_path?" do
    subject do
      described_class.new(ExpansionRules).valid_link_types_path?(link_types_path)
    end

    context "when the path matches a MultiLevelLinks entry exactly" do
      let(:link_types_path) { %i[taxons root_taxon] }
      it { is_expected.to be true }
    end

    context "when the path matches a MultiLevelLinks entry with RecurringLinks" do
      let(:link_types_path) { %i[associated_taxons associated_taxons] }
      it { is_expected.to be true }
    end

    context "when the path matches the beginning of a MultiLevelLinks entry" do
      let(:link_types_path) { %i[ordered_cabinet_ministers role_appointments] }
      it { is_expected.to be true }
    end

    context "when the path doesn't match a MultiLevelLinks entry at all" do
      let(:link_types_path) { %i[made_up_link_type] }
      it { is_expected.to be false }
    end
  end
end
