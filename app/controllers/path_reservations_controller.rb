class PathReservationsController < ApplicationController
  def reserve_path
    response = with_event_logging(Commands::ReservePath, path_item) do
      Commands::ReservePath.call(path_item)
    end

    render status: response.code, json: response
  end

private
  def path_item
    payload.merge(base_path: base_path)
  end
end
