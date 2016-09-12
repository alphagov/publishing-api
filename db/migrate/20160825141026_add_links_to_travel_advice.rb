class AddLinksToTravelAdvice < ActiveRecord::Migration
  def change
    Link.find_each("passthrough_hash IS NOT NULL") do |link|
      link.update_attributes!(target_content_id: link.passthrough_hash[:content_id])
    end
  end
end
