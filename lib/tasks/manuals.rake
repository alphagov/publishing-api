# FIXME: Remove this task once it has been run in production
namespace :manuals do
  desc "Temporary task to migration specialist publisher manuals to manuals publisher"
  task migrate: :environment do
    specialist_publisher_manuals = ContentItem.where(
      publishing_app: "specialist-publisher", document_type: %w(manual manual_section))

    specialist_publisher_manuals.each do |manual|
      # Find the Location of each specialist publisher content item
      location = Location.find_by(content_item: manual)
      # Find the PathReservation for that Location
      path_reservation = PathReservation.find_by(publishing_app: "specialist-publisher",
                                                 base_path: location.base_path)
      # Update the PathReservation if it exists
      path_reservation.update_attribute(:publishing_app, "manuals-publisher") if path_reservation
    end

    # Update the publishing_app for all specialist publisher manuals
    specialist_publisher_manuals.update_all(publishing_app: "manuals-publisher")

    puts "Migrated #{specialist_publisher_manuals.count} manuals and sections from specialist-publisher to manuals-publisher"
  end
end
