class State < ActiveRecord::Base
  belongs_to :content_item

  validates_with ContentItemUniquenessValidator

  def self.filter(content_item_scope, name:)
    content_item_scope
      .joins("INNER JOIN states ON states.content_item_id = content_items.id")
      .where("states.name" => name)
  end

  def self.supersede(content_item)
    change_state(content_item, name: "superseded")
  end

  def self.publish(content_item)
    change_state(content_item, name: "published")
  end

  def self.withdraw(content_item)
    change_state(content_item, name: "withdrawn")
  end

  def self.change_state(content_item, name:)
    state = self.find_by!(content_item: content_item)
    state.update_attributes!(name: name)
  end
end
