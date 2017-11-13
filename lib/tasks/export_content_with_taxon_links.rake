namespace :export_content_with_taxon_links do
  desc "Export content with taxon links"
  task export: :environment do
    editions = Edition
                .where(content_store: 'live')
                .where.not(document_type: %w(gone redirect taxon hmrc_manual_section))
                .limit(10000)
                .offset(100000)
    # version_number seems to be irrelevant when querying for data
    version_number = 0

    File.open(Rails.root.join("tmp", "content_with_taxon_links.json"), "w") do |f|
      f.write("[")
      # only prepend comma after first instance
      add_comma = false
      count = 0

      editions.find_each do |edition|
        payload = DownstreamPayload.new(edition, version_number, draft: true).content_store_payload
        taxons = payload.dig(:expanded_links, :taxons)
        body = payload.dig(:details, :body)
        publishing_organisation = payload[:expanded_links][:primary_publishing_organisation].first[:title] if payload.dig(:expanded_links, :primary_publishing_organisation).any?

        output = payload
                  .slice(
                    :content_id,
                    :title,
                    :locale,
                    :description,
                    :base_path,
                    :document_type,
                    :first_published_at,
                    :publishing_app,
                  )
                  .merge(body: body)
                  .merge(taxons: taxons)
                  .merge(primary_publishing_organisation: publishing_organisation)

        f.write(',') if add_comma
        add_comma ||= true
        f.write(output.to_json)

        count += 1
        puts "Exported #{count} content items" if count % 1000 == 0
      end

      f.write("]")
    end
  end
end
