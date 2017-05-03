class ChangeSpecialistFrontendToGovernmentFrontend < ActiveRecord::Migration[5.0]
  def up
    editions_to_change.update_all(rendering_app: "government-frontend")
  end

  def down
    editions_to_change.update_all(rendering_app: "specialist-frontend")
  end

  def editions_to_change
    Edition.where(
      schema_name: ["specialist_document", "placeholder_specialist_document"],
    )
  end
end
