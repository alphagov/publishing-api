require_relative "helpers/supersede_previous_published_or_unpublished"

class SupersedePreviousPublishedOrUnpublished < ActiveRecord::Migration
  def up
    superseded_count = Helpers::SupersedePreviousPublishedOrUnpublished.run
    puts "Superseded #{superseded_count} states"
  end
end
