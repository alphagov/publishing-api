require "csv"

namespace :csv_report do
  desc "Finds all references to a word being used across full details fields - pass in comma separated list of words"
  task word_usages: :environment do |_, args|
    words = args.extras.to_a.uniq
    batch_size = 1000
    fields = %i[base_path title content_id locale publishing_app document_type]

    csv = CSV.new($stdout)
    csv << fields + %i[words]

    live_editions = Edition.where(content_store: "live", state: "published")

    total = live_editions.count

    live_editions.includes(:document).find_each(batch_size:).with_index do |item, checked|
      warn "checked #{checked}/#{total} (found #{csv.lineno - 1})" if (checked % batch_size).zero?

      to_check = "#{item.title} #{item.description} #{item.details}"

      matches = []
      words.each { |word| matches << word if to_check.match?(/((?:\A|\W)#{word}(?:\W|\Z))/i) }

      if matches.any?
        csv << item.to_h.values_at(*fields) + [matches.join(",")]
      end
    end

    warn "Completed search, found #{csv.lineno - 1} matches"
  end

  desc "Prints a CSV of all editions that were published between the from and until timestamp"
  task :publishings_by_date_range, %i[from until] => :environment do |_, args|
    from_time = Time.zone.parse(args[:from])
    until_time = Time.zone.parse(args[:until])

    raise ArgumentError, "Please enter from and until times" if !from_time || !until_time

    csv = CSV.new($stdout)

    csv << %w[published_at base_path content_id locale title document_type update_type first_publishing]

    Time.use_zone("UTC") do
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
  end

  desc "Prints a CSV of all editions that were unpublished between the from and until timestamp"
  task :unpublishings_by_date_range, %i[from until] => :environment do |_, args|
    from_time = Time.zone.parse(args[:from])
    until_time = Time.zone.parse(args[:until])

    raise ArgumentError, "Please enter from and until times" if !from_time || !until_time

    csv = CSV.new($stdout)

    csv << %w[unpublished_at base_path content_id locale title document_type unpublishing_type]

    Time.use_zone("UTC") do
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
end
