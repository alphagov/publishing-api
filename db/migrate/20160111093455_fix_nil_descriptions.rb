# https://trello.com/c/DHVC2pH1/488-bug-investigate-why-description-encapsulation-has-been-bypassed
class FixNilDescriptions < ActiveRecord::Migration
  class DraftContentItem < ActiveRecord::Base; end
  class LiveContentItem < ActiveRecord::Base; end

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
