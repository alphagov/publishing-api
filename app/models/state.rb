class State < ApplicationRecord
  belongs_to :content_item

  def self.filter(content_item_scope, name:)
    join_content_items(content_item_scope)
      .where("states.name" => name)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN states ON states.content_item_id = content_items.id"
    )
  end

  def self.publish(content_item)
    change_state(content_item, name: "published")
  end

  def self.unpublish(content_item, type:, explanation: nil, alternative_path: nil, unpublished_at: nil)
    content_item.update_attributes!(state: "unpublished")

    unpublishing = Unpublishing.find_by(content_item: content_item)

    unpublished_at = nil unless type == "withdrawal"

    if unpublishing.present?
      unpublishing.update_attributes(
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
        unpublished_at: unpublished_at,
      )
      unpublishing
    else
      Unpublishing.create!(
        content_item: content_item,
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
        unpublished_at: unpublished_at,
      )
    end
  end

  def self.substitute(content_item)
    unpublish(content_item,
      type: "substitute",
      explanation: "Automatically unpublished to make way for another content item",
    )
  end

  def self.change_state(content_item, name:)
    state = self.find_by!(content_item: content_item)
    state.update_attributes!(name: name)
  end
  private_class_method :change_state
end
