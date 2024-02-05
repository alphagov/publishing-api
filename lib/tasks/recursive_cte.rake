def union(*args)
  case args
  in [left]
    left.arel
  in left, *rest
    Arel::Nodes::Union.new(left.arel, union(*rest))
  else
    raise "Unexpected args list #{args}"
  end
end

def cte(name, definition)
  Arel::Nodes::Cte.new(Arel.sql(name), definition)
end

def forward_link_set_links(content_id)
  Link
    .joins(:link_set)
    .select("link_type", "links.target_content_id")
    .where(link_sets: { content_id: content_id })
end

def reverse_link_set_links(content_id)
  Link
    .joins("INNER JOIN expansion_reverse_rules ON expansion_reverse_rules.link_type = links.link_type")
    .joins(:link_set)
    .select("link_type", "link_sets.content_id")
    .where(link_sets: { target_content_id: content_id })
end

def forward_edition_links(content_id)
  Link
    .left_joins(edition: :document)
    .select("link_type", "links.target_content_id")
    .where(
      documents: { content_id: },
      editions: {
        content_store: "live",
        locale: "en",
      },
    )
end

def reverse_edition_links(content_id)
  Link
    .joins("INNER JOIN expansion_reverse_rules ON expansion_reverse_rules.link_type = links.link_type")
    .left_joins(edition: :document)
    .select("link_type", "documents.content_id")
    .where(
      links: { target_content_id: content_id },
      editions: {
        content_store: "live",
        locale: "en",
      },
    )
end

def root_links_by_link_type_query(content_id)
  union(
    forward_link_set_links(content_id),
    reverse_link_set_links(content_id),
    forward_edition_links(content_id),
    reverse_edition_links(content_id),
  )
end

def child_links_by_link_type_query(content_id)
  # TODO: adapt these for child level links
  # We'll need to make this quite a bit more complex...
  #
  # Firstly we'll need a new recursive CTE -
  # the base case is the second level of depth,
  # the recursive case is the third level and deeper.
  # In the base case, we need to refer to the links
  # we found in root_links_by_link_type, in the recursive
  # case we need to refer to the links we found in child_links_by_link_type
  #
  # Postgres only allows us to refer to a the recursive reference once,
  # so we'll either need to wrap child_link_by_link_type in its own CTE,
  # or be clever with the other CTEs we need so it's only called once.
  #
  # The other thing we need to do here is create a mechanism for filtering
  # the allowed link types for each content_id at each level. This involves
  # recursively walking through the link_types path we've taken so far, and
  # finding the possible link types for the level we're at. This can probably happen first.
  #
  # A correct implementation of just the first and second levels of depth
  # would be a good next step.
  union(
    forward_link_set_links(content_id),
    reverse_link_set_links(content_id),
    # NOTE: edition links only supported at the root level currently
    # forward_edition_links(content_id),
    # reverse_edition_links(content_id),
  )
end

namespace :recursive_cte do
  desc "Sum the numbers from 1 to 100 using SQL"
  task sum_to_100: :environment do
    cte_table = Arel::Table.new(:t)

    base_case = Arel::Nodes::ValuesList.new([[1]])
    recursive_case = cte_table
        .project(cte_table[:n] + 1)
        .where(cte_table[:n].lt(100))

    cte_definition = Arel::Nodes::Cte.new(
      Arel.sql("t(n)"),
      Arel::Nodes::Union.new(base_case, recursive_case),
    )

    cte = cte_table.project(cte_table[:n].sum).with(:recursive, cte_definition)

    puts cte.to_sql

    result = ActiveRecord::Base.connection.execute(cte.to_sql).to_a
    puts result
  end

  desc "Working Arel version of the recursive CTE to calculate link expansions"
  task my_links_query: :environment do
    content_id = "1234"

    child_links_by_link_type = Arel::Table.new(:child_links_by_link_type)
    puts child_links_by_link_type
      .project("link_type", "content_type")
      .with(
        cte(
          "root_links_by_link_type(link_type, content_id)",
          root_links_by_link_type_query(content_id),
        ),
        cte(
          "child_links_by_link_type(link_type, content_id)",
          child_links_by_link_type_query(content_id),
        ),
      ).to_sql
  end
end
