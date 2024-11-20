class GetHostContentService
  def initialize(target_content_id, order, page, per_page)
    @target_content_id = target_content_id
    @order = order
    @page = page.blank? ? 0 : page.to_i - 1
    @per_page = per_page.blank? ? nil : per_page.to_i
  end

  def call
    if Document.find_by(content_id: target_content_id).nil?
      message = "Could not find an edition to get host content for"
      raise CommandError.new(code: 404, message:)
    end

    Presenters::HostContentPresenter.present(
      target_content_id,
      host_content,
      query.count,
      query.total_pages,
    )
  end

private

  attr_accessor :target_content_id, :order, :page, :per_page

  def query
    @query ||= Queries::GetHostContent.new(target_content_id, order_field:, order_direction:, page:, per_page:)
  end

  def host_content
    @host_content ||= query.call
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
