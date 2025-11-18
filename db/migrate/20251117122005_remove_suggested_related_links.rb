class RemoveSuggestedRelatedLinks < ActiveRecord::Migration[8.0]
  def up
    say_with_time "Removing suggested_ordered_related_items from edition_links" do
      Link.where(link_type: "suggested_ordered_related_items").delete_all
    end
  end

  def down; end
end
