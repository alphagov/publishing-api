class MoveMetadataFieldsToTopLevel < ActiveRecord::Migration
  def change
    add_column :draft_content_items, :need_ids, :json, default: []
    add_column :draft_content_items, :update_type, :string
    add_column :draft_content_items, :phase, :string, default: "live"
    add_column :draft_content_items, :analytics_identifier, :string

    add_column :live_content_items, :need_ids, :json, default: []
    add_column :live_content_items, :update_type, :string
    add_column :live_content_items, :phase, :string, default: "live"
    add_column :live_content_items, :analytics_identifier, :string

    [DraftContentItem, LiveContentItem].each do |klass|
      puts "Migrating #{klass} data..."

      klass.all.each do |item|
        item.need_ids = item.metadata[:need_ids] || []
        item.update_type = item.metadata[:update_type]
        item.phase = item.metadata[:phase] || "live"
        item.analytics_identifier = item.metadata[:analytics_identifier]

        puts item.base_path
        $stdout.flush

        item.save(validate: false)
      end

      puts
    end
  end
end
