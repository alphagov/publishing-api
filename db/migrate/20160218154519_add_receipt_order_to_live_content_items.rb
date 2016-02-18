class AddReceiptOrderToLiveContentItems < ActiveRecord::Migration
  def change
    add_column :live_content_items, :receipt_order, :integer
  end
end
