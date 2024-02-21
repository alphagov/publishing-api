class RemoveWorldwideOffices < ActiveRecord::Migration[7.1]
  def up
    Edition.where(document_type: "worldwide_office", state: "published").find_each(&:substitute)
  end
end
