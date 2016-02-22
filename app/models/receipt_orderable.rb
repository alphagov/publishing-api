module ReceiptOrderable
  extend ActiveSupport::Concern

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
