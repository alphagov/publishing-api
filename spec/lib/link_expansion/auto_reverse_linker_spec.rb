RSpec.describe LinkExpansion::AutoReverseLinker do
  include DependencyResolutionHelper

  # The linker only reads a node's link_type and mutates its links hash, so the
  # spec uses a minimal stand-in for the expander's Node.
  let(:node_class) { Data.define(:link_type, :links) }

  def node(link_type)
    node_class.new(link_type:, links: {})
  end

  def apply(root_edition, nodes, with_drafts: false)
    described_class.new(root_edition:, with_drafts:).apply(nodes)
  end

  it "back-links reverse-type nodes to the root under the direct link type" do
    root = create_edition(SecureRandom.uuid, "/root")
    child = node(:children)

    apply(root, [child])

    expect(child.links).to match(
      parent: [a_hash_including(base_path: "/root", links: {})],
    )
  end

  it "fans out to every direct type behind the reverse type (role_appointments => person / role)" do
    root = create_edition(SecureRandom.uuid, "/appointment")
    appointment = node(:role_appointments)

    apply(root, [appointment])

    expect(appointment.links.keys).to eq(%i[person role])
    expect(appointment.links.values).to all(
      match([a_hash_including(base_path: "/appointment", links: {})]),
    )
  end

  it "leaves nodes of non-reverse link types alone" do
    root = create_edition(SecureRandom.uuid, "/root")
    organisation = node(:organisation)

    apply(root, [organisation])

    expect(organisation.links).to eq({})
  end

  it "does nothing when there is no root edition" do
    child = node(:children)

    apply(nil, [child])

    expect(child.links).to eq({})
  end

  describe "unpublished root editions" do
    it "still back-links the permitted unpublished link types" do
      root = create_edition(SecureRandom.uuid, "/root", factory: :withdrawn_unpublished_edition)
      child = node(:children)

      apply(root, [child])

      expect(child.links.keys).to eq([:parent])
    end

    it "does not back-link other link types" do
      root = create_edition(SecureRandom.uuid, "/root", factory: :withdrawn_unpublished_edition)
      appointment = node(:role_appointments)

      apply(root, [appointment])

      expect(appointment.links).to eq({})
    end
  end
end
