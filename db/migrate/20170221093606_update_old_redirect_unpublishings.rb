class UpdateOldRedirectUnpublishings < ActiveRecord::Migration[5.0]
  def up
    Unpublishing
      .where(type: :redirect)
      .where(redirects: nil)
      .find_each do |unpublishing|
        # this magical line works because the 'redirects' getter is overriden
        # to generate a JSON blob automatically if it is nil within the
        # database
        unpublishing.update_attribute(:redirects, unpublishing.redirects)
      end
  end
end
