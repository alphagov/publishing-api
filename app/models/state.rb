class State < ActiveRecord::Base
  belongs_to :content_item

  validates_with ContentItemUniquenessValidator

  def self.filter(content_item_scope, name:)
    join_content_items(content_item_scope)
      .where("states.name" => name)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN states ON states.content_item_id = content_items.id"
    )
  end

  def self.supersede(content_item)
    change_state(content_item, name: "superseded")
  end

  def self.publish(content_item)
    change_state(content_item, name: "published")
  end

  def self.unpublish(content_item, type:, explanation: nil, alternative_path: nil)
    change_state(content_item, name: "unpublished")

    if unpublishing = Unpublishing.find_by(content_item: content_item)
      unpublishing.update_attributes(
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
      )
    else
      Unpublishing.create!(
        content_item: content_item,
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
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
