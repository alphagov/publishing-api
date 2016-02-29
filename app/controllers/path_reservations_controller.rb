class PathReservationsController < ApplicationController
  def reserve_path
    response = Commands::ReservePath.call(path_item)
    render status: response.code, json: response
  end

private

  def path_item
    payload.merge(base_path: base_path)
  end
end
