class SupersedePreviousPublishedOrUnpublished < ActiveRecord::Migration
  def up
    superseded_count = Helpers::SupersedePreviousPublishedOrUnpublished.run
    puts "Superseded #{superseded_count} states"
  end
end
