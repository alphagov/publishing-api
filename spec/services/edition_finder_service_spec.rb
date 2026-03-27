RSpec.describe EditionFinderService do
  let(:base_path) { "/base-path" }
  let(:exact_routes) { [] }
  let(:prefix_routes) { [] }
  let(:redirects) { [] }
  let(:routes) do
    [{ path: base_path, type: "exact" }] +
      exact_routes.map { |path| { path:, type: "exact" } } +
      prefix_routes.map { |path| { path:, type: "prefix" } }
  end

  shared_examples "it gives precedence to draft editions" do
    context "when there are both draft and live matches" do
      before do
        @draft = create(:draft_edition, base_path:, routes:, redirects:)
      end

      it { is_expected.to eq @draft }
    end

    context "when there's only a draft match" do
      before do
        @live.destroy!

        @draft = create(:draft_edition, base_path:, routes:, redirects:)
      end

      it { is_expected.to eq @draft }
    end

    context "when there's only a live match" do
      it { is_expected.to eq @live }
    end
  end

  shared_examples "it never uses draft editions" do
    context "when there are both draft and live matches" do
      before do
        @draft = create(:draft_edition, base_path:, routes:, redirects:)
      end

      it { is_expected.to eq @live }
    end

    context "when there's only a draft match" do
      before do
        @live.destroy!

        @draft = create(:draft_edition, base_path:, routes:, redirects:)
      end

      it { is_expected.to be_nil }
    end

    context "when there's only a live match" do
      it { is_expected.to eq @live }
    end
  end

  before do
    @live = @edition = create(:live_edition, base_path:, routes:, redirects:)
  end

  describe ".find" do
    subject { described_class.new(request_path).find }

    context "when there isn't an item matching the path" do
      let(:request_path) { "/path" }

      it { is_expected.to be_nil }
    end

    context "when there are base_paths that match the path" do
      let(:request_path) { "/base-path" }

      context "with_drafts=true" do
        subject { described_class.new(request_path, with_drafts: true).find }

        it_behaves_like "it gives precedence to draft editions"
      end

      context "with_drafts=false" do
        subject { described_class.new(request_path, with_drafts: false).find }

        it_behaves_like "it never uses draft editions"
      end
    end

    context "when there are matching exact routes for the path" do
      let(:exact_route_path) { "/base-path/exact-route" }
      let(:request_path) { exact_route_path }
      let(:exact_routes) { [exact_route_path] }

      context "with_drafts=true" do
        subject { described_class.new(request_path, with_drafts: true).find }

        it_behaves_like "it gives precedence to draft editions"

        context "and there is also a base_path that matches the exact route path" do
          let!(:superseding_instance) { create(:live_edition, base_path: exact_route_path) }

          it { is_expected.to eq superseding_instance }
        end
      end

      context "with_drafts=false" do
        subject { described_class.new(request_path, with_drafts: false).find }

        it_behaves_like "it never uses draft editions"

        context "and there is also a base_path that matches the exact route path" do
          let!(:superseding_instance) { create(:live_edition, base_path: exact_route_path) }

          it { is_expected.to eq superseding_instance }
        end
      end
    end

    context "when there are matching exact redirects for the path" do
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

      context "with_drafts=true" do
        subject { described_class.new(request_path, with_drafts: true).find }

        it_behaves_like "it gives precedence to draft editions"
      end

      context "with_drafts=false" do
        subject { described_class.new(request_path, with_drafts: false).find }

        it_behaves_like "it never uses draft editions"
      end
    end

    context "when there are routes with a prefix match" do
      let(:prefix_route_path) { "/base-path/prefix-route" }
      let(:prefix_routes) { [prefix_route_path] }

      context "and the path matches the prefix path" do
        let(:request_path) { prefix_route_path }

        context "with_drafts=true" do
          subject { described_class.new(request_path, with_drafts: true).find }

          it_behaves_like "it gives precedence to draft editions"
        end

        context "with_drafts=false" do
          subject { described_class.new(request_path, with_drafts: false).find }

          it_behaves_like "it never uses draft editions"
        end
      end

      context "and the path is in a segment after the prefix path" do
        let(:request_path) { "/base-path/prefix-route/a/b/c" }

        context "with_drafts=true" do
          subject { described_class.new(request_path, with_drafts: true).find }

          it_behaves_like "it gives precedence to draft editions"
        end

        context "with_drafts=false" do
          subject { described_class.new(request_path, with_drafts: false).find }

          it_behaves_like "it never uses draft editions"
        end
      end

      context "and the path includes additional segments after the prefix" do
        let(:request_path) { "/base-path/prefix-route-longer-path" }

        context "with_drafts=true" do
          subject { described_class.new(request_path, with_drafts: true).find }

          it "finds nothing as this isn't supported" do
            is_expected.to be nil
          end
        end

        context "with_drafts=false" do
          subject { described_class.new(request_path, with_drafts: false).find }

          it "finds nothing as this isn't supported" do
            is_expected.to be nil
          end
        end
      end

      context "but there are other items with a better path match" do
        let(:request_path) { "/base-path/prefix-route/with-extra/segments" }

        before do
          @live_better_prefix_match = create(
            :live_edition,
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
            ],
          )
        end

        context "with_drafts=true" do
          subject { described_class.new(request_path, with_drafts: true).find }

          before do
            @draft = create(:draft_edition, base_path:, routes:, redirects:)
          end

          context "when there are both draft and live better matches" do
            before do
              @draft_better_prefix_match = create(
                :draft_edition,
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
                ],
              )
            end

            it { is_expected.to eq @draft_better_prefix_match }
          end

          context "when there's only a draft better match" do
            before do
              @live_better_prefix_match.destroy!

              @draft_better_prefix_match = create(
                :draft_edition,
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
                ],
              )
            end

            it { is_expected.to eq @draft_better_prefix_match }
          end

          context "when there's only a live better match" do
            it { is_expected.to eq @live_better_prefix_match }
          end
        end

        context "with_drafts=false" do
          subject { described_class.new(request_path, with_drafts: false).find }

          context "when there are both draft and live better matches" do
            before do
              @draft_better_prefix_match = create(
                :draft_edition,
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
                ],
              )
            end

            it { is_expected.to eq @live_better_prefix_match }
          end

          context "when there's only a draft better match" do
            before do
              @live_better_prefix_match.destroy!

              @draft_better_prefix_match = create(
                :draft_edition,
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
                ],
              )
            end

            it { is_expected.to eq @live }
          end

          context "when there's only a live better match" do
            it { is_expected.to eq @live_better_prefix_match }
          end
        end
      end

      context "but there are other items with an exact path match" do
        let(:request_path) { [prefix_route_path] }

        before do
          @live_exact_match = create(
            :live_edition,
            base_path: "/base-path/prefix-route",
            routes: [
              {
                path: "/base-path/prefix-route",
                type: "exact",
              },
            ],
          )
        end

        context "with_drafts=true" do
          subject { described_class.new(request_path, with_drafts: true).find }

          before do
            @draft = create(:draft_edition, base_path:, routes:, redirects:)
          end

          context "when there are both draft and live exact matches" do
            before do
              @draft_exact_match = create(
                :draft_edition,
                base_path: "/base-path/prefix-route",
                routes: [
                  {
                    path: "/base-path/prefix-route",
                    type: "exact",
                  },
                ],
              )
            end

            it { is_expected.to eq @draft_exact_match }
          end

          context "when there's only a draft exact match" do
            before do
              @live_exact_match.destroy!

              @draft_exact_match = create(
                :draft_edition,
                base_path: "/base-path/prefix-route",
                routes: [
                  {
                    path: "/base-path/prefix-route",
                    type: "exact",
                  },
                ],
              )
            end

            it { is_expected.to eq @draft_exact_match }
          end

          context "when there's only a live exact match" do
            it { is_expected.to eq @live_exact_match }
          end
        end

        context "with_drafts=false" do
          subject { described_class.new(request_path, with_drafts: false).find }

          context "when there are both draft and live exact matches" do
            before do
              @draft_exact_match = create(
                :draft_edition,
                base_path: "/base-path/prefix-route",
                routes: [
                  {
                    path: "/base-path/prefix-route",
                    type: "exact",
                  },
                ],
              )
            end

            it { is_expected.to eq @live_exact_match }
          end

          context "when there's only a draft exact match" do
            before do
              @live_exact_match.destroy!

              @draft_exact_match = create(
                :draft_edition,
                base_path: "/base-path/prefix-route",
                routes: [
                  {
                    path: "/base-path/prefix-route",
                    type: "exact",
                  },
                ],
              )
            end

            it { is_expected.to be_nil }
          end

          context "when there's only a live exact match" do
            it { is_expected.to eq @live_exact_match }
          end
        end
      end
    end
  end
end
