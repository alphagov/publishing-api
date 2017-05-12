class SyncWhitehallPublicUpdatedAt < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    schema_names = %w(gone redirect special_route speech statistical_data_set take_part topical_event_about_page)

    schema_names.each do |schema_name|
      scope = Edition.where(publishing_app: "whitehall")
                     .where(schema_name: schema_name)
                     .where("first_published_at AT TIME ZONE 'Europe/London' > public_updated_at")

      # Sync all the timestamps
      scope.update_all("public_updated_at = first_published_at")
      puts "#{scope.count} records updated for schema '#{schema_name}'"
      puts "(#{scope.pluck(:id).join(",")})"

      # Narrow the scope to find current content
      current_editions_scope = scope.where(state: %w(draft published))
      current_edition_content_ids = current_editions_scope.map(&:content_id)

      if Rails.env.production? && current_editions_scope.any?
        # Represent current editions downstream
        Commands::V2::RepresentDownstream.new.call(current_edition_content_ids, with_drafts: true)

        # Output what has been updated downstream
        puts "The following items have been represented downstream:"
        puts current_editions_scope.map(&:base_path).uniq.sort
      end
    end
  end
end
