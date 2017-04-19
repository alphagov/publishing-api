class CopyDescriptionValuesToDescription2 < ActiveRecord::Migration[5.0]
  def up
    Edition.all.each do |edition|
      string_description = edition.description.to_s
      edition.update_attribute(:description2, string_description)
    end
  end

  def down
    Edition.update_all(description2: nil)
  end
end
