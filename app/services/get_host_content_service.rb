class GetHostContentService
  def initialize(target_content_id, order)
    @target_content_id = target_content_id
    @order = order
  end

  def call
    if Document.find_by(content_id: target_content_id).nil?
      message = "Could not find an edition to get embedded content for"
      raise CommandError.new(code: 404, message:)
    end

    Presenters::EmbeddedContentPresenter.present(
      target_content_id,
      host_content,
    )
  end

private

  attr_accessor :target_content_id, :order

  def host_content
    @host_content ||= Queries::GetEmbeddedContent.new(target_content_id, order_field:, order_direction:).call
  rescue KeyError
    message = "Invalid order field: #{order}"
    raise CommandError.new(
      code: 422,
      message:,
      error_details: {
        error: {
          code: 422,
          message:,
        },
      },
    )
  end

  def order_direction
    return nil if order.blank?

    order.start_with?("-") ? :desc : :asc
  end

  def order_field
    return nil if order.blank?

    (order_direction == :desc ? order[1..] : order).to_sym
  end
end
