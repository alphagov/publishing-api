module ReceiptOrderable
  extend ActiveSupport::Concern

  included do
    after_save :increment_receipt_order
    after_touch :increment_receipt_order
  end

  def increment_receipt_order
    klass = self.class
    sql = <<-SQL
        UPDATE #{ klass.table_name}
        SET receipt_order = COALESCE(receipt_order, 0) + 1
        WHERE id = #{ self.id }
        RETURNING receipt_order;
      SQL
    self.receipt_order = DraftContentItem.connection
      .execute(sql)
      .first["receipt_order"]
  end
end
