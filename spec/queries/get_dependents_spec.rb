require "rails_helper"

RSpec.describe Queries::GetDependents do
  subject { described_class.new }

  def create_node
    link_set = FactoryGirl.create(:link_set, content_id: SecureRandom.uuid)
    link_set.content_id
  end

  def create_edge(from, to, link_type)
    link_set = LinkSet.find_by(content_id: from)

    FactoryGirl.create(
      :link,
      link_set: link_set,
      target_content_id: to,
      link_type: link_type
    )
  end

  let(:a) { create_node }
  let(:b) { create_node }
  let(:c) { create_node }
  let(:d) { create_node }

  it "finds nodes that depend on the given node" do
    create_edge(a, c, "parent")
    create_edge(b, c, "parent")

    expect(subject.call(content_id: c, recursive_link_types: ["parent"])).to match_array [a, b]
  end

  it "finds nodes that depend on the given node through different types" do
    create_edge(a, c, "parent")
    create_edge(b, a, "children")

    expect(subject.call(content_id: c, recursive_link_types: %w(parent children))).to match_array [a, b]
  end

  it "finds direct links only" do
    create_edge(a, c, "parent")
    create_edge(b, a, "parent")

    expect(subject.call(content_id: c, direct_link_types: ["parent"])).to match_array [a]
  end

  it "finds direct and recursive links types" do
    create_edge(a, c, "parent")
    create_edge(b, a, "parent")

    expect(subject.call(content_id: c, recursive_link_types: ['parent'], direct_link_types: ["parent"])).to match_array [a, b]
  end

  it "does not find nodes that do not depend on the given node" do
    create_edge(a, c, "parent")

    expect(subject.call(content_id: c, recursive_link_types: ["parent"])).not_to include(b)
  end

  it "does not find nodes that are connected with a different link_type" do
    create_edge(a, c, "parent")
    create_edge(b, c, "something_else")

    expect(subject.call(content_id: c, recursive_link_types: ["parent"])).not_to include(b)
  end

  it "returns empty when no link types are provided" do
    create_edge(a, c, "parent")
    create_edge(b, c, "something_else")

    expect(subject.call(content_id: c)).to match_array []
  end

  it "returns an empty array if no nodes depend on the given node" do
    expect(subject.call(content_id: a, recursive_link_types: "parent")).to be_empty
  end

  it "finds nodes that transitively depend on the given node" do
    create_edge(a, b, "parent")
    create_edge(b, c, "parent")

    expect(subject.call(content_id: c, recursive_link_types: "parent")).to match_array [a, b]
  end

  it "does not find nodes where the outbound edge is the wrong link_type" do
    create_edge(a, b, "something_else")
    create_edge(b, c, "parent")

    expect(subject.call(content_id: c, recursive_link_types: "parent")).to eq [b]
  end

  it "does not find nodes where an intermediate edge is the wrong link_type" do
    create_edge(a, b, "parent")
    create_edge(b, c, "something_else")
    create_edge(c, d, "parent")

    expect(subject.call(content_id: d, recursive_link_types: "parent")).to eq [c]
  end

  it "terminates when the graph has cycles" do
    create_edge(a, b, "related")
    create_edge(b, a, "related")

    expect(subject.call(content_id: b)).to eq []
  end
end
