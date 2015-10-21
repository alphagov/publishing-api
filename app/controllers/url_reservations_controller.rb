class UrlReservationsController < ApplicationController
  def reserve_url
    render json: Commands::ReserveUrl.call(payload.merge(base_path: base_path))
  end
end
