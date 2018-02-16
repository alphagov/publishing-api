class RemoveChangeHistoryForEdition < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  
  def change
    begin
      edition = Edition.find(2975826)
  
      if edition.present?
        edition_details = edition.details
        edition_details.delete(:change_history)
        edition.update!(details: edition_details)
    
        if Rails.env.production?
          Commands::V2::RepresentDownstream.new.call(edition.content_id)
        end
      end
    rescue StandardError => e
      puts "Could not find edition. Error: #{e.message}"
    end
  end
end
