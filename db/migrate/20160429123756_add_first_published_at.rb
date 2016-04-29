class AddFirstPublishedAt < ActiveRecord::Migration
  def up
    add_column :content_items, :first_published_at, :datetime

    content_item_scope = ContentItem.all
    scope = State.filter(content_item_scope, name: "superseded")
    scope = Translation.join_content_items(scope)
    scope = UserFacingVersion.join_content_items(scope)
    scope = scope.select(:id, :content_id, :locale, :number, :name)

    first_superseded_cis_scope = ContentItem.joins <<-SQL
      INNER JOIN (
        WITH scope AS (#{scope.to_sql})
        SELECT s1.id FROM scope s1
        LEFT OUTER JOIN scope s2 ON
          s1.content_id = s2.content_id AND
          s1.locale = s2.locale AND
          s1.number > s2.number
        WHERE s2.content_id IS NULL
      ) AS latest_versions
      ON latest_versions.id = content_items.id
    SQL

    print "Loading first superseded content item for each content_id.."
    STDOUT.flush
    first_superseded_cis = first_superseded_cis_scope.to_a
    puts "loaded.  Updating first_published_at.."
    first_superseded_cis.each do |ci|
      print "."
      STDOUT.flush
      ContentItem.where(content_id: ci.content_id).update_all(first_published_at: ci.created_at)
    end
    puts "Done."

    all_published_cis = State.filter(ContentItem.all, name: "published")

    print "Loading published content item for each content_id where never superseded.."
    STDOUT.flush
    published_but_never_superseded_cis = all_published_cis.where.not(
      content_id: first_superseded_cis_scope.pluck(:content_id)
    ).to_a
    puts " loaded.  Updating first_published_at.."
    published_but_never_superseded_cis.each do |ci|
      print "."
      STDOUT.flush
      ContentItem.where(content_id: ci.content_id).update_all(first_published_at: ci.created_at)
    end
    puts "Done."
  end

  def down
    remove_column :content_items, :first_published_at
  end
end
