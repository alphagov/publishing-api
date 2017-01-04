class RemoveInvalidContentIds < ActiveRecord::Migration[5.0]
  def up
    events_to_remove = [20, 41, 83, 51, 42, 61, 40, 44, 41, 39, 42, 40, 26, 83,
                        89, 88, 90, 86, 88, 87, 89, 90, 87, 92, 26, 39, 61, 20,
                        44, 51, 29, 18, 94, 86, 87, 94, 18, 29, 89, 90]

    Event.where(content_id: events_to_remove).destroy_all

    link_sets_to_remove = [40, 42, 26, 39, 61, 20, 41, 83, 51, 44, 90, 88, 29,
                           18, 86, 89, 87, 94, 92]

    LinkSet.where(content_id: link_sets_to_remove).destroy_all
  end
end
