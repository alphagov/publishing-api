class UpdateMissingPublisherFirstPublishedAtDates < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    Edition
      .where.not(temporary_first_published_at: nil, first_published_at: nil)
      .where("temporary_first_published_at != first_published_at")
      .where("publisher_first_published_at IS NULL OR publisher_first_published_at != first_published_at")
      .find_each do |edition|
        edition.update(publisher_first_published_at: edition.first_published_at)
      end
  end
end
