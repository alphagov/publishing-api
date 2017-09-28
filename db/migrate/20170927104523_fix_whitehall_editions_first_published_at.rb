class FixWhitehallEditionsFirstPublishedAt < ActiveRecord::Migration[5.1]
  def up
    start_datetime = "2016-02-29 09:24:09"
    end_datetime = "2016-02-29 09:24:11"

    # 5184 records
    Edition
      .where("first_published_at BETWEEN '#{start_datetime}' AND '#{end_datetime}'")
      .where(publishing_app: "whitehall")
      .where.not(document_type: "placeholder")
      .where("(details->'first_public_at') IS NOT NULL")
      .where.not("(details->>'first_public_at')::date BETWEEN '#{start_datetime}' AND '#{end_datetime}'")
      .find_each do |edition|
        edition.update(first_published_at: edition.details[:first_public_at])
      end
  end
end
