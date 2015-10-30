class RedirectsValidator < ActiveModel::Validator
  def validate(record)
    return unless record.base_path.present?

    record.redirects.each do |redirect|
      RedirectValidator.new.validate(record, redirect)
    end
  end

  class RedirectValidator
    def validate(record, redirect)
      destination = redirect[:destination]

      unless destination.present?
        record.errors[:redirects] << "destination must be present"
      end

      validator = AbsolutePathValidator.new(attributes: :redirects)
      validator.validate_each(record, :redirects, destination)
    end
  end
end
