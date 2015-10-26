class PathReservationsController < ApplicationController
  def reserve_path
    render json: Commands::ReservePath.call(payload.merge(base_path: base_path))
  end
end
