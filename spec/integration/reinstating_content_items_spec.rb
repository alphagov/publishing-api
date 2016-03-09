require "rails_helper"

RSpec.describe "Reinstating Content Items" do
  let(:put_content_command) { Commands::V2::PutContent }
  let(:publish_command) { Commands::V2::Publish }

  it "does not raise an error that a duplicate superseded content item has been detected " \
    "when republishing a content item after a redirect withdrew the original" do
    guide_draft_payload = {
      content_id: SecureRandom.uuid,
      base_path: '/vat-rates',
      title: "Guide Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      format: "guide",
      locale: "en",
      routes: [{ path: "/vat-rates", type: "exact" }],
      redirects: [],
      phase: "beta",
    }
    guide_publish_payload = {
      content_id: guide_draft_payload[:content_id],
      update_type: "major",
    }

    redirect_draft_payload = {
      content_id: SecureRandom.uuid,
      base_path: '/vat-rates',
      destination: "/somewhere",
      title: "Redirect Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      format: "redirect",
      locale: "en",
      routes: [],
      redirects: [{ path: "/vat-rates", type: "exact", destination: "/somewhere" }],
      phase: "beta",
    }
    redirect_publish_payload = {
      content_id: redirect_draft_payload[:content_id],
      update_type: "major",
    }

    # Save and publish a guide twice to create a superseded content item
    2.times do
      put_content_command.call(guide_draft_payload)
      publish_command.call(guide_publish_payload)
    end

    # Save and publish a redirect for the same base path
    put_content_command.call(redirect_draft_payload)
    publish_command.call(redirect_publish_payload)

    # Save and publish the guide again to withdraw the redirect
    put_content_command.call(guide_draft_payload)
    publish_command.call(guide_publish_payload)

    # Save and publish the guide a final time to supersede the previous
    # content item
    expect {
      put_content_command.call(guide_draft_payload)
      publish_command.call(guide_publish_payload)
    }.not_to raise_error
  end
end
