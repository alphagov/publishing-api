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
end
