require "rails_helper"

RSpec.describe Queries::GetDependents do
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

  it "finds nodes that depend on the given node" do
    a = create_node
    b = create_node
    c = create_node

    create_edge(a, c, "parent")
    create_edge(b, c, "parent")

    results = described_class.call(c, "parent")
    expect(results).to match_array [a, b]
  end

  it "does not find nodes that do not depend on the given node" do
    a = create_node
    b = create_node
    c = create_node

    create_edge(a, c, "parent")

    results = described_class.call(c, "parent")
    expect(results).not_to include(b)
  end

  it "does not find nodes that are connected with a different link_type" do
    a = create_node
    b = create_node
    c = create_node

    create_edge(a, c, "parent")
    create_edge(b, c, "something_else")

    results = described_class.call(c, "parent")
    expect(results).not_to include(b)
  end

  it "can optionally omit link_type to return all dependent nodes" do
    a = create_node
    b = create_node
    c = create_node

    create_edge(a, c, "parent")
    create_edge(b, c, "something_else")

    results = described_class.call(c)
    expect(results).to match_array [a, b]
  end

  it "returns an empty array if no nodes depend on the given node" do
    a = create_node

    results = described_class.call(a, "parent")
    expect(results).to be_empty
  end

  it "finds nodes that transitively depend on the given node" do
    a = create_node
    b = create_node
    c = create_node

    create_edge(a, b, "parent")
    create_edge(b, c, "parent")

    results = described_class.call(c, "parent")
    expect(results).to match_array [a, b]
  end

  it "does not find nodes where the outbound edge is the wrong link_type" do
    a = create_node
    b = create_node
    c = create_node

    create_edge(a, b, "something_else")
    create_edge(b, c, "parent")

    results = described_class.call(c, "parent")
    expect(results).to eq [b]
  end

  it "does not find nodes where an intermediate edge is the wrong link_type" do
    a = create_node
    b = create_node
    c = create_node
    d = create_node

    create_edge(a, b, "parent")
    create_edge(b, c, "something_else")
    create_edge(c, d, "parent")

    results = described_class.call(d, "parent")
    expect(results).to eq [c]
  end

  it "can optionally omit link_type to return all transitively dependent nodes" do
    a = create_node
    b = create_node
    c = create_node
    d = create_node

    create_edge(a, b, "parent")
    create_edge(b, c, "something_else")
    create_edge(c, d, "parent")

    results = described_class.call(d)
    expect(results).to match_array [a, b, c]
  end

  it "terminates when the graph has cycles" do
    a = create_node
    b = create_node

    create_edge(a, b, "related")
    create_edge(b, a, "related")

    results = described_class.call(b)
    expect(results).to eq [a]
  end

  it "runs performantly for a relatively large dependency graph" do
    content_id = create_node

    inserts = []

    # Builds a four-level tree that fans out ten nodes at a time.
    1.upto(10) do |i|
      i_id = SecureRandom.uuid
      inserts << dependency_sql(from: i_id, to: content_id)

      1.upto(10) do |j|
        j_id = SecureRandom.uuid
        inserts << dependency_sql(from: j_id, to: i_id)

        1.upto(10) do |k|
          k_id = SecureRandom.uuid
          inserts << dependency_sql(from: k_id, to: j_id)

          1.upto(10) do |l|
            l_id = SecureRandom.uuid
            inserts << dependency_sql(from: l_id, to: k_id)
          end
        end
      end
    end

    ActiveRecord::Base.connection.execute(inserts.join(";"))

    results = nil
    time_taken = Benchmark.realtime do
      results = described_class.call(content_id)
    end

    expect(results.size).to eq(10 + 100 + 1000 + 10000)
    expect(time_taken).to be < 0.25
  end

  def dependency_sql(from:, to:)
    @id ||= 100
    @id += 1

    <<-SQL
      INSERT INTO link_sets (id, content_id)
      VALUES (#{@id}, '#{from}');

      INSERT INTO links (
        id,
        link_set_id,
        target_content_id,
        link_type,
        created_at,
        updated_at
      )
      VALUES (#{@id}, #{@id}, '#{to}', 'parent', now(), now())
    SQL
  end
end
