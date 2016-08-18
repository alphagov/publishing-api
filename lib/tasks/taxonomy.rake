# TODO: After running this task, it can be deleted
namespace :taxonomy do
  desc 'Change ownership of taxons from collections-publisher to content-tagger'
  task change_ownership: :environment do
    ActiveRecord::Base.transaction do
      taxons = ContentItem.where(document_type: 'taxon', publishing_app: "collections-publisher")
      puts "Found #{taxons.count} taxons"

      taxons.each do |taxon|
        puts "Changing #{taxon.title} from #{taxon.publishing_app} to content-tagger"
        taxon.update!(publishing_app: 'content-tagger')
      end

      puts ""

      path_reservations = PathReservation.where("base_path LIKE '/alpha-taxonomy%'").where(publishing_app: "collections-publisher")
      if path_reservations.present?
        puts "Found #{path_reservations.count} path reservations belonging to collections publisher"
        path_reservations.each do |path_reservation|
          puts "Updating #{path_reservation.base_path} to content-tagger"
          path_reservation.update_column(publishing_app: "content-tagger")
        end
      end
    end
  end
end
