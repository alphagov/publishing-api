# https://trello.com/c/DHVC2pH1/488-bug-investigate-why-description-encapsulation-has-been-bypassed
class FixNilDescriptions < ActiveRecord::Migration[4.2]
  class DraftContentItem < ApplicationRecord; end
  class LiveContentItem < ApplicationRecord; end

  def up
    models = [DraftContentItem, LiveContentItem]

    models.each do |m|
      m.find_each do |item|
        description = item.description

        if description.is_a?(Hash)
          item.description = description.fetch(:value)
          item.save!(validate: false)
        end
      end
    end
  end

  def down
    # noop
  end
end
