require "csv"

namespace :csv_report do
  desc "Prints a CSV of all editions that were published between the from and until timestamp"
  task :publishings_by_date_range, %i[from until] => :environment do |_, args|
    from_time = Time.zone.parse(args[:from])
    until_time = Time.zone.parse(args[:until])

    raise ArgumentError, "Please enter from and until times" if !from_time || !until_time

    csv = CSV.new($stdout)

    csv << %w[published_at base_path content_id locale title document_type update_type first_publishing]

    query = Edition.joins(:document)
                   .where(published_at: from_time...until_time)
                   .where.not(update_type: :republish)
                   .order(published_at: :asc)
                   .pluck(:published_at,
                          :base_path,
                          "documents.content_id",
                          "documents.locale",
                          :title,
                          :document_type,
                          :update_type,
                          Arel.sql("(user_facing_version = 1)"))

    query.each { |row| csv << row }
  end

  desc "Prints a CSV of all editions that were unpublished between the from and until timestamp"
  task :unpublishings_by_date_range, %i[from until] => :environment do |_, args|
    from_time = Time.zone.parse(args[:from])
    until_time = Time.zone.parse(args[:until])

    raise ArgumentError, "Please enter from and until times" if !from_time || !until_time

    csv = CSV.new($stdout)

    csv << %w[unpublished_at base_path content_id locale title document_type unpublishing_type]

    query = Unpublishing.joins({ edition: :document })
                        .where(created_at: from_time...until_time)
                        .where.not(type: "substitute")
                        .order(created_at: :asc)
                        .pluck(:created_at,
                               "editions.base_path",
                               "documents.content_id",
                               "documents.locale",
                               "editions.title",
                               "editions.document_type",
                               :type)

    query.each { |row| csv << row }
  end
end
