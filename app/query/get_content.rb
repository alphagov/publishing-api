class Query::GetContent
  attr_reader :content_id

  def initialize(content_id)
    @content_id = content_id
  end

  def call
    DraftContentItem.find_by!(content_id: content_id)
  end
end
