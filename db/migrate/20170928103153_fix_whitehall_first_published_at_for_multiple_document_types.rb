require "csv"

class FixWhitehallFirstPublishedAtForMultipleDocumentTypes < ActiveRecord::Migration[5.1]
  def up
    update_count = 0
    start_datetime = "2016-02-29 09:24:09"
    end_datetime = "2016-02-29 09:24:11"

    %w(about press_release news_story).each do |document_type|
      format_count = 0

      data = CSV.read(Rails.root.join("db", "migrate", "data", "#{document_type}_first_published_at.csv"))

      data.each do |content_id, first_published_at|
        if first_published_at
          format_count += Edition
            .joins(:document)
            .where("first_published_at BETWEEN '#{start_datetime}' AND '#{end_datetime}'")
            .where(publishing_app: "whitehall", document_type: document_type)
            .where(documents: { content_id: content_id })
            .update_all(first_published_at: first_published_at)
        end
      end

      puts "Updated #{format_count} editions with document_type: #{document_type}"
      update_count += format_count
    end

    puts "#{update_count} editions updated."
  end
end
