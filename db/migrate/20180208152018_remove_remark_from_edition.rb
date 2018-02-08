class RemoveRemarkFromEdition < ActiveRecord::Migration[5.1]
  def change
    begin
      edition = Edition.find(805386)
    
      remarks = edition.editorial_remarks
    
      remarks_to_delete = remarks.select{|r| r.body == "HTML attachment published here in error. Removed and added back here https://whitehall-admin.publishing.service.gov.uk/government/admin/publications/805384"}

      remarks_to_delete.each { |r| r.destroy }
    rescue StandardError => e
      puts "Migration has failed with the following error: #{e.message}"
    end
  end
end
