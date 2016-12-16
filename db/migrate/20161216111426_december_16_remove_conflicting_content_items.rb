class December16RemoveConflictingContentItems < ActiveRecord::Migration[5.0]
  def up
    to_remove = [
      1066093, # conflicts with 1066092 - same base_path, state and user_facing_version
      # The remaining are all version conflicts, they don't have base_paths
      # all are contacts from whitehall
      1035642, # conflicts with 1035643
      1078051, # conflicts with 1078053
      1035336, # conflicts with 1035337
      1235630, # conflicts with 1235630
      1035342, # conflcits with 1035343
      1066050, # conflicts with 1066051
      1038420, # conflicts with 1038420
      1055010, # conflicts with 1055011
      1054963, # conflicts with 1054962
      1302370, # conflicts with 1302371
      1481684, # conflicts with 1481685
      1059527, # conflicts with 1059528
      1299098, # conflicts with 1299099
      1067658, # conflicts with 1067659
    ]
    content_items = ContentItem.where(id: to_remove)
    Services::DeleteContentItem.destroy_supporting_objects(content_items)
    content_items.destroy_all
  end

  def down
  end
end
