class UniqueChangeNoteForContentItem < ActiveRecord::Migration[5.0]
  def change
    puts "Setting content_ids"
    ChangeNote.connection.execute(<<-SQL
      UPDATE change_notes cn SET content_id = ci.content_id
      FROM content_items ci WHERE cn.content_item_id = ci.id
      SQL
    )

    # For each major change published since change history was originally
    # migrated, delete all change notes other than the last one created since
    # the change was published.
    puts "Deleting duplicates"
    dupes = []
    UserFacingVersion.join_content_items(ContentItem.where(
      "public_updated_at > '2016-10-18' AND publishing_app = 'specialist-publisher' AND update_type = 'major'"
    )).each do |content_item|
      change_notes = ChangeNote.where("public_timestamp > '2016-10-18' AND content_item_id = ?", content_item.id).order(public_timestamp: :desc).pluck(:id)
      dupes.concat(change_notes.from(1))
    end
    puts "#{dupes.count} notes to delete"
    ChangeNote.where(id: dupes).delete_all

    # For each content_id, set most recent change note to most recent major
    # update (draft or published) and other change notes content_items to nil.
    # 97% of change notes are the only one for their content id, so limit the
    # query to where that is not true.
    puts "Calculating content item relationships"
    multiple_change_notes.map(&:content_id).each do |content_id|
      ChangeNote.where(content_id: content_id).update_all(content_item_id: nil)
      sql = <<-SQL
        UPDATE change_notes SET content_item_id = (
          SELECT ci.id FROM content_items ci
          INNER JOIN user_facing_versions ufv ON ufv.content_item_id = ci.id
          WHERE content_id = '#{content_id}'
          AND update_type = 'major'
          ORDER BY number DESC LIMIT 1
        )
        WHERE id = (
          SELECT id FROM change_notes WHERE content_id='#{content_id}'
          ORDER BY public_timestamp DESC LIMIT 1
        )
      SQL
      ChangeNote.connection.execute(sql)
      print '.'
    end
  end

  def multiple_change_notes
    ChangeNote.select(:content_id).having('COUNT(*) > 1').group(:content_id)
  end
end
