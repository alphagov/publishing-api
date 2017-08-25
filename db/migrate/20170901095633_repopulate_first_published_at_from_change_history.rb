class RepopulateFirstPublishedAtFromChangeHistory < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    min_date = '2016-02-29T09:24:09'
    max_date = '2016-02-29T09:24:11'
    document_ids = []
    statements_ary = []

    sql = <<-SQL.strip_heredoc
      SELECT e.id,
             e.document_id,
             hist->>'public_timestamp'
      FROM   editions e,
             json_array_elements(details->'change_history') hist
      WHERE  e.document_type != 'placeholder'
      AND    e.first_published_at BETWEEN '#{min_date}' AND '#{max_date}'
      AND    hist IS NOT NULL
      AND    hist->>'note' = 'First published.'
      AND    hist->>'public_timestamp' NOT BETWEEN '#{min_date}' AND '#{max_date}'
    SQL

    # ~224000 records
    results = ActiveRecord::Base.connection.execute(sql).values
    puts "#{results.size} records found with change history and first_published_at on 2016-02-29."

    results.each do |edition_id, document_id, timestamp|
      statements_ary << "UPDATE editions SET first_published_at = '#{timestamp}' WHERE id = #{edition_id};"
      document_ids << document_id
    end

    statements_ary.each_slice(1000).each do |statements|
      ActiveRecord::Base.connection.execute(statements.join("\n"))
    end

    if Rails.env.production?
      document_content_ids = Document.where(id: document_ids.uniq).pluck(:content_id)
      puts "Representing #{document_content_ids.size} items downstream."
      Commands::V2::RepresentDownstream.new.call(document_content_ids)
    end
  end
end
