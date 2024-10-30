class AddStatisticsCaches < ActiveRecord::Migration[7.2]
  def change
    create_table :statistics_caches do |t|
      t.integer :unique_pageviews, null: false
      t.references :document, index: { unique: true }

      t.timestamps
    end
  end
end
