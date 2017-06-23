class AddMissingPublicUpdatedTimestamps < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    editions_to_update = Edition
      .where(publishing_app: "specialist-publisher")
      .where(public_updated_at: nil)
      .where(state: "published")

    puts "Populating `public_updated_at` for #{editions_to_update.size} editions"

    editions_to_update.each do |edition|
      edition.public_updated_at = edition.first_published_at
      edition.save
    end
  end
end
