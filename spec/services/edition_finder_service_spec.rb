RSpec.describe EditionFinderService do
  let(:scope) { Edition }

  let(:base_path) { "/base-path" }
  let(:exact_routes) { [] }
  let(:prefix_routes) { [] }
  let(:redirects) { [] }
  let(:routes) do
    [{ path: base_path, type: "exact" }] +
      exact_routes.map { |path| { path:, type: "exact" } } +
      prefix_routes.map { |path| { path:, type: "prefix" } }
  end

  before do
    @edition = create(:live_edition, base_path:, routes:, redirects:)
  end

  describe ".find" do
    subject { described_class.new(scope).find(request_path) }

    context "when there isn't an item matching the path" do
      let(:request_path) { "/path" }

      it { is_expected.to be_nil }
    end

    context "when there is a base_path that matches the path" do
      let(:request_path) { "/base-path" }

      it { is_expected.to eq @edition }
    end

    context "when there is a matching exact route for the path" do
      let(:exact_route_path) { "/base-path/exact-route" }
      let(:request_path) { exact_route_path }
      let(:exact_routes) { [exact_route_path] }

      it { is_expected.to eq @edition }

      context "and there is also a base_path that matches the exact route path" do
        let!(:superseding_instance) { create(:live_edition, base_path: exact_route_path) }

        it { is_expected.to eq superseding_instance }
      end
    end

    context "when there is a matching exact redirect for the path" do
      let(:request_path) { "/base-path/exact-route" }

      let(:redirects) do
        [
          {
            destination: "/somewhere",
            path: "/base-path/exact-route",
            type: "exact",
          },
        ]
      end

      it { is_expected.to eq @edition }
    end

    context "when there is a route with a prefix match" do
      let(:prefix_route_path) { "/base-path/prefix-route" }
      let(:prefix_routes) { [prefix_route_path] }

      context "and the path matches the prefix path" do
        let(:request_path) { prefix_route_path }
        it { is_expected.to eq @edition }
      end

      context "and the path is in a segment after the prefix path" do
        let(:request_path) { "/base-path/prefix-route/a/b/c" }
        it { is_expected.to eq @edition }
      end

      context "and the path includes additional segments after the prefix" do
        let(:request_path) { "/base-path/prefix-route-longer-path" }
        it "finds nothing as this isn't supported" do
          is_expected.to be nil
        end
      end

      context "but there is another item with a better path match" do
        let(:request_path) { "/base-path/prefix-route/with-extra/segments" }

        before do
          @better_prefix_match = create(:live_edition,
                                        base_path: "/base-path/prefix-route",
                                        routes: [
                                          {
                                            path: "/base-path/prefix-route",
                                            type: "exact",
                                          },
                                          {
                                            path: "/base-path/prefix-route/with-extra",
                                            type: "prefix",
                                          },
                                        ])
        end

        it { is_expected.to eq @better_prefix_match }
      end

      context "but there is another item with an exact path match" do
        let(:request_path) { [prefix_route_path] }

        before do
          @exact_match = create(:live_edition,
                                base_path: "/base-path/prefix-route",
                                routes: [
                                  {
                                    path: "/base-path/prefix-route",
                                    type: "exact",
                                  },
                                ])
        end

        it { is_expected.to eq @exact_match }
      end
    end
  end
end
