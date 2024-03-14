class DeleteSpecialistTopicsFromDatabase < ActiveRecord::Migration[7.1]
  def up
    # Using document_type instead of schema_name for speed.
    # This migration will also delete the dependents
    # of each edition: links and unpublishings.

    published_topics_count = select_one(<<~SQL)["count"]
      SELECT COUNT(*) AS count
      FROM editions
      WHERE document_type = 'topic'
      AND state = 'published';
    SQL

    published_topics = select_all(<<~SQL)
      SELECT id, title, base_path, publishing_app
      FROM editions
      WHERE document_type = 'topic'
      AND state = 'published'
      LIMIT 100;
    SQL

    unless published_topics_count.zero?
      say <<~MESSAGE
        There are still #{published_topics_count} published specialist topics.
        Below there are listed up to the first 100 of them.
        [id, title, base_path, publishing_app]
        #{published_topics.rows.collect(&:to_s).join("\n")}
      MESSAGE
      raise "Migration aborted because there are still some published specialist topics"
    end

    deleted_count = delete(<<~SQL)
      DELETE FROM editions
      WHERE document_type = 'topic';
    SQL

    say "Deleted #{deleted_count} specialist topic editions"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
