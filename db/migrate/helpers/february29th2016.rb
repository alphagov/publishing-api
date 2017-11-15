module Helpers
  # Something perculiar happened to the Publishing API database either on or
  # around the 29th February 2016 - which in itself a perculiar date as it only
  # exists once every 4 years.
  #
  # Somehow all of the records in the editions table (which was then the
  # content_items table) had all of their timestamps changed to the same date
  # eg.
  #     pp Edition.where("id <= 3").pluck(:created_at, :updated_at,
  #     :first_published_at)
  #     [[Mon, 29 Feb 2016 09:24:10 UTC +00:00,
  #       Mon, 29 Feb 2016 09:24:10 UTC +00:00,
  #       Mon, 29 Feb 2016 09:24:10 UTC +00:00],
  #      [Mon, 29 Feb 2016 09:24:10 UTC +00:00,
  #       Mon, 29 Feb 2016 09:24:10 UTC +00:00,
  #       Mon, 29 Feb 2016 09:24:10 UTC +00:00],
  #      [Mon, 29 Feb 2016 09:24:10 UTC +00:00,
  #       Mon, 29 Feb 2016 09:24:10 UTC +00:00,
  #       Mon, 29 Feb 2016 09:24:10 UTC +00:00]]
  #
  # We're not sure why or how this happened. Theories are it was either an
  # overly zealous data migration or somehow shipping with Timecop.freeze
  #
  # But anyway this module provides some helper methods to clean up the mess
  module February29th2016
    START_DATETIME = "2016-02-29 09:24:09"
    END_DATETIME = "2016-02-29 09:24:11"

    def self.replace_first_published_at(
      data,
      content_id_position: 0,
      first_published_at_position: 1,
      where_conditions: {}
    )
      count = data.inject(0) do |memo, row|
        if row[first_published_at_position]
          memo += Edition
            .joins(:document)
            .where("first_published_at BETWEEN '#{START_DATETIME}' AND '#{END_DATETIME}'")
            .where(
              where_conditions.merge(
                "documents.content_id": row[content_id_position]
              )
            )
            .update_all(first_published_at: row[first_published_at_position])
        end
        memo
      end

      puts "#{count} editions updated."
    end
  end
end
