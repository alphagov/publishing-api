class AbsolutePathValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_absolute_url_path?(value)
      record.errors[attribute] << "is not a valid absolute URL path"
    end
  end

private

  def valid_absolute_url_path?(path)
    return false unless path.present? and path.starts_with?("/")

    uri = URI.parse(path)
    uri.path == path && path !~ %r{//} && path !~ %r{./\z}
  rescue URI::InvalidURIError
    false
  end
end
