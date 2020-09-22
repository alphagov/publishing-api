namespace :content do
  #See git commit log on this comment for details
  desc "Updates a country name for specialist publications"
  task :update_specialist_publication_countries, %i[old_country new_country] => :environment do |_, args|
    if args.old_country.blank? || args.new_country.blank?
      raise ArgumentError, "This task takes two arguments: the current country name and the new country name."
    end

    health = Edition.where(document_type: 'export_health_certificate')
    puts "Attempting to update type: export_health_certificate"
    filt_health = health.select { |h| h.details[:metadata][:destination_country].present? && h.details[:metadata][:destination_country].include?(args.old_country) }
    filt_health.each do |doc|
      puts "Processing #{doc.title}"
      details = doc.details
      met = details[:metadata]
      met[:destination_country].map! { |c| c == args.old_country ? args.new_country : c }
      details[:metadata] = met
      doc.details = details
      doc.save
    end

    interdevfund = Edition.where(document_type: 'international_development_fund')
    puts "Attempting to update type: international_development_fund"
    filt_fund = interdevfund.select { |h| h.details[:metadata][:location].present? && h.details[:metadata][:location].include?(args.old_country) }
    filt_fund.each do |doc|
      puts "Processing #{doc.title}"
      details = doc.details
      met = details[:metadata]
      met[:location].map! { |c| c == args.old_country ? args.new_country : c }
      details[:metadata] = met
      doc.details = details
      doc.save
    end
  end
end
