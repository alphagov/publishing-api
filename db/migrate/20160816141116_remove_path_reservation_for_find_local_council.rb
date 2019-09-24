class RemovePathReservationForFindLocalCouncil < ActiveRecord::Migration[4.2]
  def change
    # Actually fully delete this path reservation.
    # It was created to reserve a path for an artefact that was created in
    # error on launch day and immediately archived without publishing (or
    # even completing the creation of the associated edition in publisher).
    # We want to reuse the route without leaving something lying around
    # that could accidently be used to alter that route from panopticon.
    PathReservation.where(base_path: "/find-local-council", publishing_app: "publisher").destroy_all
  end
end
