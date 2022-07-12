RSpec.describe ExpansionRules::MultiLevelLinks do
  let(:multi_level_link_paths) do
    [
      %i[red blue],
      [[:yellow]],
      [:yellow, [:green]],
    ]
  end
  let(:backwards) { false }

  describe "#allowed_link_types" do
    subject(:instance) do
      described_class.new(multi_level_link_paths, backwards:)
    end

    context "when in forwards mode" do
      specify do
        expect(instance.allowed_link_types([:red])).to match([:blue])
      end
      specify do
        expect(instance.allowed_link_types([:blue])).to be_empty
      end
      specify do
        expect(instance.allowed_link_types([:yellow])).to match(%i[yellow green])
      end
      specify do
        expect(instance.allowed_link_types(%i[yellow green])).to match([:green])
      end
    end

    context "when in backwards mode" do
      let(:backwards) { true }
      specify do
        expect(instance.allowed_link_types([:blue])).to match([:red])
      end
      specify do
        expect(instance.allowed_link_types([:red])).to be_empty
      end
      specify do
        expect(instance.allowed_link_types([:yellow])).to match([:yellow])
      end
      specify do
        expect(instance.allowed_link_types([:green])).to match(%i[yellow green])
      end
    end
  end

  describe "#paths" do
    subject do
      described_class.new(multi_level_link_paths, backwards:)
        .paths(length:)
    end

    context "when in forwards mode" do
      context "when length is 1" do
        let(:length) { 1 }
        let(:length_1) do
          [
            %i[red blue],
            [:yellow],
            %i[yellow green],
          ]
        end
        it { is_expected.to match(length_1) }
      end

      context "when paths is 3" do
        let(:length) { 3 }
        let(:length_3) do
          [
            %i[red blue],
            %i[yellow yellow yellow],
            %i[yellow green green],
          ]
        end
        it { is_expected.to match(length_3) }
      end
    end

    context "when in backwards mode" do
      let(:backwards) { true }

      context "when length is 2" do
        let(:length) { 2 }
        let(:length_2) do
          [
            %i[blue red],
            %i[yellow yellow],
            %i[green yellow],
          ]
        end
        it { is_expected.to match(length_2) }
      end

      context "when paths is 4" do
        let(:length) { 4 }
        let(:length_4) do
          [
            %i[blue red],
            %i[yellow yellow yellow yellow],
            %i[green green green yellow],
          ]
        end
        it { is_expected.to match(length_4) }
      end
    end
  end

  describe ".next_allowed_link_types" do
    subject do
      described_class.new(multi_level_link_paths, backwards:)
        .next_allowed_link_types(link_types, link_types_path)
    end

    context "when there is an empty link_types_path" do
      let(:link_types) { %i[yellow red] }
      let(:link_types_path) { [] }

      it { is_expected.to match(yellow: %i[yellow green], red: [:blue]) }
    end

    context "when there is a link_types_path" do
      let(:link_types) { [:green] }
      let(:link_types_path) { [:yellow] }

      it { is_expected.to match(green: [:green]) }
    end

    context "when there are no links" do
      let(:link_types) { [:red] }
      let(:link_types_path) { [:green] }

      it { is_expected.to be_empty }
    end

    context "when the class is initialized with backwards true" do
      let(:backwards) { true }
      let(:link_types) { [:blue] }
      let(:link_types_path) { [] }

      it { is_expected.to match(blue: [:red]) }
    end
  end
end
