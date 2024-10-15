RSpec.describe ContentIdAlias do
  describe "validations" do
    context "when name is present" do
      subject { build(:content_id_alias, name: "my-content-id") }
      it { is_expected.to be_valid }
    end

    context "when name only contains whitespace" do
      subject { build(:content_id_alias, name: "     ") }
      it { is_expected.not_to be_valid }
    end

    context "when name is an empty string" do
      subject { build(:content_id_alias, name: "") }
      it { is_expected.not_to be_valid }
    end

    context "when name has already been taken" do
      before do
        create(:content_id_alias, name: "my-content-id")
      end

      subject { build(:content_id_alias, name: "my-content-id") }

      it { is_expected.not_to be_valid }
    end
  end
end
