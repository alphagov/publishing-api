class FixRedirectSupersedes < ActiveRecord::Migration
  def up
    all_redirects = ContentItem.where(document_type: "redirect")
    published_redirects = ContentItemFilter.new(scope: all_redirects).filter(state: "published")

    fixed_count = 0

    puts "#{published_redirects.count} published redirects to check"

    # Around 10k at time of writing
    published_redirects.find_each do |published_redirect|
      user_facing_version = UserFacingVersion.find_by(content_item: published_redirect)
      location = Location.find_by(content_item: published_redirect)
      translation = Translation.find_by(content_item: published_redirect)

      accidentally_superseded_content_item = ContentItemFilter.filter(
        user_version: user_facing_version.number,
        base_path: location.base_path,
        locale: translation.locale,
        state: "superseded",
      ).last

      if accidentally_superseded_content_item
        puts "Withdrawing [ #{user_facing_version.number} | superseded | #{location.base_path} | #{translation.locale} ]"
        state = State.find_by(content_item: accidentally_superseded_content_item)
        state.update_attributes(name: "withdrawn")
        fixed_count += 1
      end
    end

    puts "Found and fixed #{fixed_count} problems with the #{published_redirects.count} published redirects"
  end
end
