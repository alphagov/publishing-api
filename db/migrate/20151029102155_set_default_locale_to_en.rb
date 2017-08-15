class SetDefaultLocaleToEn < ActiveRecord::Migration[4.2]
  def change
    change_column_default :draft_content_items, :locale, "en"
    change_column_default :live_content_items, :locale, "en"
  end
end
