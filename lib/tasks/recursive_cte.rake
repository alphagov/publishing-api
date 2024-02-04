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

def forward_link_set_links(content_id)
  Link
    .joins(:link_set)
    .select(:link_type, "links.target_content_id")
    .where("link_sets.content_id": content_id)
end

def reverse_link_set_links(content_id)
  Link
    .joins("INNER JOIN expansion_reverse_rules ON expansion_reverse_rules.link_type = links.link_type")
    .joins(:link_set)
    .select(:link_type, "link_sets.content_id")
    .where("link_sets.target_content_id": content_id)
  # TODO allowed link types
end

def forward_edition_links(content_id)
  Link.left_joins(edition: :document)
    .select(:link_type, "links.target_content_id")
    .where(
      documents: { content_id: },
      editions: {
        content_store: "live",
        locale: "en",
      },
    )
end

def reverse_edition_links(content_id)
  Link.left_joins(edition: :document)
      .select(:link_type, "documents.content_id")
      .where(
        links: { target_content_id: content_id },
        editions: {
          content_store: "live",
          locale: "en",
        },
  )
  # TODO allowed link types
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

  task my_links_query: :environment do
    content_id = "1234"

    puts union(
      forward_link_set_links(content_id),
      reverse_link_set_links(content_id),
      forward_edition_links(content_id),
      reverse_edition_links(content_id),
    ).to_sql
  end
end
