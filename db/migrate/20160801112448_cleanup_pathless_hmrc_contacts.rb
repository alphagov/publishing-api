class CleanupPathlessHmrcContacts < ActiveRecord::Migration
  def change
    # There approx 800 contact ContentItems.
    ContentItem.where(schema_name: "contact", publishing_app: "contacts").find_each do |item|
      path = item.routes.first[:path]

      # Approx 25 records have no Location supporting object.
      unless Location.find_by(content_item: item)
        Location.create!(base_path: path, content_item: item)
        puts "Added location '#{path}' for content item #{item.id}"
      end
    end
  end
end
