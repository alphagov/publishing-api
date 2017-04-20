class CopyDescriptionValuesToDescriptionString < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    Edition.in_batches do |relation|
      execute("UPDATE editions
               SET description_string=description ->> 'value'
               WHERE id IN (#{relation.pluck(:id).join(', ')})")
    end
  end
end
