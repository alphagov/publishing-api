class DropPassthroughHashFromLinks < ActiveRecord::Migration[4.2]
  def change
    Link.where("passthrough_hash IS NOT NULL").each do |link|
      link.update!(target_content_id: link.passthrough_hash[:content_id])
    end
    remove_column :links, :passthrough_hash, :json
  end
end
