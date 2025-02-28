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
      request = dataloader.with(described_class).request([
        person_1.content_id,
        %i[id base_path title details],
      ])

      expect(request.load).to eq([role_1, role_3])
    end
  end
end
