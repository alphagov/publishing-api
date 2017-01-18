# The History
# ===========
#
# In whitehall a Person object was created for John Corderoy on 29th Nov
# 2016.  The base path for this Person is /government/people/john-corderoy,
# and the content_id is 27b08e2d-1bd9-428d-a6c9-c6ffa40d166a.  Like all
# Person objects this was sent to publishing-api immediately upon
# creation and published, registering the route with router in the
# process.  For some reason it was almost immediately deleted from
# whitehall and publishing-api told to unpublish the content item (telling
# router to 410 the path in the process).
#
# A couple of minutes later a new Person object was created for John which
# has the same base path but a different content_id:
#     eab84eb0-6a02-4d50-9644-0900e7b8cee7
# When saved in whitehall this Person is drafted onto the publishing-api,
# but cannot be published, because it's trying to reuse the same base_path
# as an existing content_item with a different content_id.

# If this new content item was published then the publishing-api and
# content-store would be in sync with the whitehall db and things would
# be better.  However, visiting the url for John's page would still get
# you a 410 because although publishing is now possible and publishing-api
# would then tell content-store about the new content item, it turns out
# that content-store doesn't manage routes for "placeholder" items
# and Person objects from whitehall are "placeholder" (because they're not
# fully migration) so cotent-store doesn't manage routes for them.
#
# The problme is that when it was deleted we published a "gone" item which
# content-store does manage routes for.  When it is subsequently
# re-published it goes back to being a "placeholder" and content-store
# doesn't manage the route, leaving the 410 route in place.
#
# The solution is to change the content_id of the old content_item to be
# the same as the content_id of the new content_item (and delete the old
# Document). This lets the whitehall, publishing-api, and content-store
# dbs sync up, and then we delete the old route (because it shouldn't be
# there any more).
class FixJohnCorderyContentItems < ActiveRecord::Migration[5.0]
  def up
    old_content_id = '27b08e2d-1bd9-428d-a6c9-c6ffa40d166a'
    new_content_id = 'eab84eb0-6a02-4d50-9644-0900e7b8cee7'

    new_content_item = ContentItem.where(content_id: new_content_id).first
    old_content_item = ContentItem.where(content_id: old_content_id).first

    # Update the user facing version of the new item, it should be +1 on what
    # it was
    new_content_item.update_column(:user_facing_version, new_content_item.user_facing_version += 1)
    UserFacingVersion.where(content_item_id: new_content_item.id).update_all(number: new_content_item.user_facing_version)

    old_document_id = old_content_item.document_id
    old_content_item.update_columns(content_id: new_content_id, document_id: new_content_item.document_id)

    # Get rid of the old document - it's not needed
    Document.delete(old_document_id)
    # Delete the LinkSet of the old content item - you can't have more than
    # one link set for a content_id, and we know it's empty anyway
    LinkSet.where(content_id: old_content_id).destroy_all
    Link.where(target_content_id: old_content_id).update_all(target_content_id: new_content_id)
    Event.where(content_id: old_content_id).update_all(content_id: new_content_id)
    Action.where(content_id: old_content_id).update_all(content_id: new_content_id)
    ChangeNote.where(content_id: old_content_id).update_all(content_id: new_content_id)

    # The final step is to remove the old route from router API
    require 'gds_api/router'
    router_api = GdsApi::Router.new(Plek.find('router-api'))
    router_api.delete_route('/government/people/john-corderoy', commit: true)

    # The actual last step is to go into whitehall and save the person to
    # trigger a new publish that will update publishing-api and content-store
  end

  def down
    # It would be pretty hard to resurrect this data structure as we can't tell
    # which of the objects originally belonged to the old content id
    raise ActiveRecord::IrreversibleMigration
  end
end
