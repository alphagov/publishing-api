class Query::GetContent
  attr_reader :content_id

  def initialize(content_id)
    @content_id = content_id
  end

  def call
    content_item = DraftContentItem.find_by(content_id: content_id)

    if content_item
      content_item
    else
      error_details = {
        error: {
          code: 404,
          message: "Could not find content item with content_id: #{content_id}"
        }
      }
      raise Command::Error.new(code: 404, error_details: error_details)
    end
  end
end
