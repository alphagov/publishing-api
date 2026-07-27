RSpec.describe DependencyResolution do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }

  def resolve(with_drafts: true)
    described_class.new(content_id, locale: "en", with_drafts:).dependencies
  end

  it "resolves a multi-level reverse chain (child_taxons) to its full depth" do
    a = SecureRandom.uuid
    b = SecureRandom.uuid
    c = SecureRandom.uuid

    create_link_set(content_id, links_hash: { parent_taxons: [a] })
    create_link_set(a, links_hash: { parent_taxons: [b] })
    create_link_set(b, links_hash: { parent_taxons: [c] })

    expect(resolve).to match_array([a, b, c])
  end

  it "does not require the dependent content to have an edition" do
    links_to = SecureRandom.uuid
    create_link_set(links_to, links_hash: { organisation: [content_id] })

    expect(resolve).to match_array([links_to])
  end

  it "bounds traversal through cycles via per-path ancestors" do
    a = SecureRandom.uuid
    b = SecureRandom.uuid

    create_link_set(a, links_hash: { parent_taxons: [content_id, b] })
    create_link_set(b, links_hash: { parent_taxons: [a] })

    expect(resolve).to match_array([a, b])
  end

  it "follows only valid multi-level link paths" do
    a = SecureRandom.uuid
    b = SecureRandom.uuid
    c = SecureRandom.uuid

    # Invalid ordering: mainstream_browse_pages then ordered_related_items is not
    # a valid path, so only the direct parent dependency is found.
    create_link_set(a, links_hash: { mainstream_browse_pages: [b] })
    create_link_set(b, links_hash: { ordered_related_items: [c] })
    create_link_set(c, links_hash: { parent: [content_id] })

    expect(resolve).to match_array([c])
  end

  it "resolves the root's outgoing edition links of reverse types without following them" do
    x = SecureRandom.uuid
    y = SecureRandom.uuid

    # The root's *edition* links to x via parent_taxons, so x presents the root
    # among its child_taxons and must be re-presented. Edition-sourced nodes
    # are terminal, so x's own links are not followed.
    create_edition(content_id, "/root", links_hash: { parent_taxons: [x] })
    create_link_set(x, links_hash: { parent_taxons: [y] })

    expect(resolve).to match_array([x])
  end

  it "does not follow edition links recursively (nested edition links unsupported)" do
    link_content_id = SecureRandom.uuid
    edition_content_id = SecureRandom.uuid

    create_link_set(link_content_id, links_hash: { parent_taxons: [content_id] })
    create_edition(
      edition_content_id,
      "/edition-links",
      links_hash: { parent_taxons: [link_content_id] },
    )

    expect(resolve).to match_array([link_content_id])
  end

  describe "role_appointments fan-out (person / role)" do
    it "resolves both the person and role reverse dependencies" do
      person = SecureRandom.uuid
      role = SecureRandom.uuid

      create_link_set(content_id, links_hash: { person: [person], role: [role] })

      expect(resolve).to match_array([person, role])
    end
  end

  describe "query count" do
    it "issues a bounded number of queries (O(depth), not O(nodes))" do
      # A wide, shallow graph: many dependents at a single level. A per-node
      # implementation would issue queries proportional to the node count and
      # blow past the bound; the batched resolver stays flat at O(depth).
      level_1 = Array.new(40) { SecureRandom.uuid }
      create_link_set(content_id, links_hash: { parent_taxons: level_1 })
      # A little depth on top of the width, so the bound covers both.
      level_2 = SecureRandom.uuid
      create_link_set(level_1.first, links_hash: { parent_taxons: [level_2] })

      queries = []
      counter = lambda do |_name, _start, _finish, _id, payload|
        queries << payload[:sql] unless payload[:name] == "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        resolve
      end

      expect(queries.count).to be < 15
    end
  end
end
