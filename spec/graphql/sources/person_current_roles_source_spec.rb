RSpec.describe Sources::PersonCurrentRolesSource do
  include MinistersIndexHelpers

  it "returns the current roles for a person" do
    person_1 = create_person("Person 1")
    role_1 = create_role("Role 1")
    role_2 = create_role("Role 2")
    role_3 = create_role("Role 3")
    appoint_person_to_role(person_1, role_1)
    appoint_person_to_role(person_1, role_2, current: false)
    appoint_person_to_role(person_1, role_3)

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class).request(person_1.content_id)

      expect(request.load).to match_array([role_1, role_3])
    end
  end

  it "does not return draft roles for a person" do
    person_1 = create_person("Person 1")
    published_role = create_role("Role")
    draft_role = create_role("Draft role")
    non_current_draft_role = create_role("Non-current draft role")
    appoint_person_to_role(person_1, published_role)
    appoint_person_to_role(person_1, draft_role, state: "draft")
    appoint_person_to_role(person_1, non_current_draft_role, state: "draft", current: false)

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class).request(person_1.content_id)

      expect(request.load).to eq([published_role])
    end
  end

  it "does not return unpublished roles for a person" do
    person_1 = create_person("Person 1")
    published_role = create_role("Role")
    unpublished_role = create_role("Unpublished role")
    non_current_unpublished_role = create_role("Non-current unpublished role")
    appoint_person_to_role(person_1, published_role)
    appoint_person_to_role(person_1, unpublished_role, state: "unpublished")
    appoint_person_to_role(person_1, non_current_unpublished_role, state: "unpublished", current: false)

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class).request(person_1.content_id)

      expect(request.load).to eq([published_role])
    end
  end
end
