class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  if Rails.env.production_replica?
    connects_to database: {
      writing: :primary,
      reading: :primary_replica,
    }
  end
end
