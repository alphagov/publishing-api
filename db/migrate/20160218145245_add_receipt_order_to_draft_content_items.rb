class AddReceiptOrderToDraftContentItems < ActiveRecord::Migration
  def change
    add_column :draft_content_items, :receipt_order, :integer
  end
end
