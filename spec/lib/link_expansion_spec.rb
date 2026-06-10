RSpec.describe LinkExpansion do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }

  let(:a) { create_link_set }
  let(:b) { create_link_set }
  let(:c) { create_link_set }
  let(:d) { create_link_set }

  def expand(content_id, with_drafts: true)
    described_class.new(content_id:, locale: "en", with_drafts:).links_with_content
  end

  describe "#links_with_content" do
    subject do
      described_class.by_content_id(content_id).links_with_content
    end

    context "no links" do
      it { is_expected.to be_empty }
      it { is_expected.to be_a(Hash) }
    end

    context "with a link" do
      let(:link) do
        create(
          :live_edition,
          title: "Expanded Link",
          base_path: "/expanded-link",
        )
      end

      let(:expected) do
        {
          related: [
            a_hash_including(title: link.title, base_path: link.base_path),
          ],
        }
      end

      before { create_link(content_id, link.document.content_id, "related") }

      it { is_expected.to match(expected) }
    end

    context "with a withdrawn link" do
      let(:link) { create(:withdrawn_unpublished_edition) }

      before { create_link(content_id, link.document.content_id, link_type) }

      context "and a parent link_type" do
        let(:link_type) { :parent }

        it { is_expected.to match(parent: [a_hash_including(withdrawn: true)]) }
      end

      context "and a related link_type" do
        let(:link_type) { :related }

        it { is_expected.to be_empty }
      end

      context "and a related_statistical_data_sets link_type" do
        let(:link_type) { :related_statistical_data_sets }

        it { is_expected.to match(related_statistical_data_sets: [a_hash_including(withdrawn: true)]) }
      end
    end

    context "with recursive links" do
      let(:child_content_id) { SecureRandom.uuid }
      let(:grand_child_content_id) { SecureRandom.uuid }
      let!(:child) { create_edition(child_content_id, "/child") }
      let!(:grand_child) { create_edition(grand_child_content_id, "/grand-child") }

      before do
        create_link(content_id, child_content_id, "parent")
        create_link(child_content_id, grand_child_content_id, "parent")
      end

      let(:expected) do
        {
          parent: [a_hash_including(
            base_path: child.base_path,
            links: {
              parent: [a_hash_including(
                base_path: grand_child.base_path,
                links: {},
              )],
            },
          )],
        }
      end

      it { is_expected.to match(expected) }
    end
  end

  describe "traversal structure" do
    before do
      create_edition(a, "/a", factory: :draft_edition)
      create_edition(b, "/b", factory: :draft_edition)
      create_edition(c, "/c", factory: :draft_edition)
      create_edition(d, "/d", factory: :draft_edition)
    end

    it "expands a multi-level recursive chain to its full depth" do
      create_link(a, b, "parent")
      create_link(b, c, "parent")
      create_link(c, d, "parent")

      expect(expand(a)[:parent]).to match([
        a_hash_including(base_path: "/b", links: {
          parent: [a_hash_including(base_path: "/c", links: {
            parent: [a_hash_including(base_path: "/d", links: {})],
          })],
        }),
      ])
    end

    it "prunes cycles per-path, not with a global visited set" do
      create_link(a, b, "parent")
      create_link(b, a, "parent")

      # the root reappears one level deep as b's parent, with its own children
      # pruned (a global visited set would have excluded it entirely)
      expect(expand(a)[:parent]).to match([
        a_hash_including(base_path: "/b", links: {
          parent: [a_hash_including(base_path: "/a", links: {})],
        }),
      ])
    end
  end

  # The order of link-type keys in the output hash is deliberately asymmetric:
  # reverse-then-direct at the root, direct-then-reverse at every deeper level.
  # This matches the way link expansion worked historically, and is observable
  # by Content Store, but it is otherwise only implied by the order of two
  # blocks in expand_root / expand_level. These tests pin it so a refactor that
  # "tidies" the two methods into one shared loop (which would naturally make
  # the orderings consistent) fails loudly rather than silently changing published output.
  describe "output key ordering" do
    it "orders root link types reverse-then-direct" do
      org = create_link_set
      child = create_link_set
      create_edition(a, "/a", factory: :draft_edition)
      create_edition(org, "/org", factory: :draft_edition)
      create_edition(child, "/child", factory: :draft_edition)

      create_link(a, org, "organisation") # a direct (link set) link from the root
      create_link(child, a, "parent")     # child is a child of a => root has :children

      expect(expand(a).keys).to eq(%i[children organisation])
    end

    it "orders child link types direct-then-reverse" do
      taxon = create_link_set         # the root; left without an edition so the
      child_taxon = create_link_set   # auto_reverse_link pass is skipped and the
      associated = create_link_set    # child's keys reflect only expand_level
      grandchild_taxon = create_link_set
      create_edition(child_taxon, "/child-taxon", factory: :draft_edition)
      create_edition(associated, "/associated", factory: :draft_edition)
      create_edition(grandchild_taxon, "/grandchild-taxon", factory: :draft_edition)

      # taxon -child_taxons-> child_taxon, reached via the reverse of parent_taxons
      create_link(child_taxon, taxon, "parent_taxons")
      # at [:child_taxons] both a direct (:associated_taxons) and a reverse
      # (:child_taxons) link type are allowed; give the child_taxon one of each
      create_link(child_taxon, associated, "associated_taxons")
      create_link(grandchild_taxon, child_taxon, "parent_taxons")

      child = expand(taxon).fetch(:child_taxons).first
      expect(child[:links].keys).to eq(%i[associated_taxons child_taxons])
    end
  end

  describe "query count" do
    before do
      create_edition(a, "/a", factory: :draft_edition)
      create_edition(b, "/b", factory: :draft_edition)
      create_edition(c, "/c", factory: :draft_edition)
      create_edition(d, "/d", factory: :draft_edition)
      create_link(a, b, "parent")
      create_link(b, c, "parent")
      create_link(c, d, "parent")
    end

    it "issues a bounded number of queries (O(depth), not O(nodes))" do
      queries = []
      counter = lambda do |_name, _start, _finish, _id, payload|
        queries << payload[:sql] unless payload[:name] == "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        expand(a)
      end

      expect(queries.count).to be < 15
    end
  end

  describe "reverse re-keying with fan-out (role_appointments => person / role)" do
    it "buckets both the person and role reverse links under :role_appointments" do
      person = create_link_set
      role = create_link_set
      appointment = create_link_set

      create_edition(appointment, "/appointment", factory: :draft_edition, document_type: "role_appointment", schema_name: "role_appointment")
      create_edition(person, "/person", factory: :draft_edition, document_type: "person", schema_name: "person")
      create_edition(role, "/role", factory: :draft_edition, document_type: "ministerial_role", schema_name: "role")

      # The appointment links to both a person and a role (the stored, "direct"
      # link types). From the person's / role's point of view these are
      # role_appointments (the reverse name).
      create_link(appointment, person, "person")
      create_link(appointment, role, "role")

      person_links = expand(person)
      role_links = expand(role)

      expect(person_links[:role_appointments].map { _1[:base_path] }).to eq(["/appointment"])
      expect(role_links[:role_appointments].map { _1[:base_path] }).to eq(["/appointment"])
    end
  end

  # Edition links are followed at the root but treated as leaf nodes, and are
  # ignored entirely below the root (see the "edition links are only followed
  # at root level" edge case in ADR-014).
  describe "edition links as terminal leaf nodes" do
    it "does not expand the links of an edition reached via a root edition link" do
      create_edition(a, "/a", factory: :draft_edition, links_hash: { parent: [b] })
      create_edition(b, "/b", factory: :draft_edition)
      create_edition(c, "/c", factory: :draft_edition)
      create_link(b, c, "parent") # would expand to /c if /b were not terminal

      expect(expand(a)[:parent]).to match([
        a_hash_including(base_path: "/b", links: {}),
      ])
    end

    it "keeps edition-sourced reverse links at the root" do
      create_edition(b, "/b", factory: :draft_edition)
      # c's *edition* links to b, so b sees c among its child_taxons
      create_edition(c, "/c", factory: :draft_edition, links_hash: { parent_taxons: [b] })

      expect(expand(b)[:child_taxons].map { _1[:base_path] }).to eq(["/c"])
    end

    it "drops edition-sourced reverse links below the root" do
      # No root edition for `a`, so the auto-reverse pass is skipped and the
      # child's links reflect only the traversal.
      create_edition(b, "/b", factory: :draft_edition)
      # the same edition link as above, but b is now one level down
      create_edition(c, "/c", factory: :draft_edition, links_hash: { parent_taxons: [b] })
      create_link(b, a, "parent_taxons") # b is a child taxon of the root

      child = expand(a).fetch(:child_taxons).first
      expect(child[:base_path]).to eq("/b")
      expect(child[:links]).to eq({})
    end
  end

  describe "no renderable root edition" do
    it "still expands link set and reverse links without auto_reverse_link" do
      # No edition exists for `a`, but it has link set links and is linked to.
      create_edition(b, "/b", factory: :draft_edition)
      create_edition(c, "/c", factory: :draft_edition)
      create_link(a, b, "organisation") # link set link from a
      create_link(c, a, "parent")       # c is a child of a

      result = expand(a)

      expect(result[:organisation].map { _1[:base_path] }).to eq(["/b"])
      expect(result[:children].map { _1[:base_path] }).to eq(["/c"])
      # auto_reverse_link is skipped (no root edition to reverse-link back to)
      expect(result[:children][0][:links]).to eq({})
    end
  end
end
