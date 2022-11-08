class RemoveDuplicateWorldwideOrganisation < ActiveRecord::Migration[7.0]
  def up
    Edition.where(document_type: "worldwide_organisation").each do |worldwide_organisation|
      Edition.where(base_path: worldwide_organisation.base_path, document_type: "about", state: "draft").delete_all
    end
  end
end
