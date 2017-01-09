class FixWelshPublisherContentLocales < ActiveRecord::Migration[5.0]
  def up
    welsh_content_ids = [
      "12cd2a97-e005-4f99-a4d1-a5e9fa1c4415",
      "b394bbec-c8f8-4b50-adbc-840b630cc007",
      "7fe4dd51-210d-4468-a988-99a742bfdc5b",
      "d1d87169-3284-43c6-96e5-dd0cbb8cf89f",
      "275a9cbc-62e9-48d8-82d6-ef460f66bc5f",
      "976ba497-dc16-4a2c-b103-f3e153d51192",
      "2176cab5-7600-493d-9e54-06c7f27297c5",
      "139577cc-8eb6-4f1f-a170-7c456f03f6b1",
      "4eda604d-76f1-4455-8281-5033c1c8596a",
      "a661e67e-52bf-4d67-a0fc-5be231255a76",
      "085e4c8b-0252-4cc3-af2f-db0edaebf539",
      "3b4755b3-df53-4a5d-a8f1-8c8c20aadb46",
      "6c1d8527-ea49-44c8-8525-21295889584e",
      "0ae4f2a6-56d7-4728-b8de-18829475bf74",
      "ee9da799-1f51-4397-8470-20af9e87fc12",
      "15075444-4e7b-4096-b81a-6dcc9bece0b7",
      "d732fb0d-1578-4d2d-8160-e3159338b554",
      "70c0579a-87b5-49b8-b888-ad7135b97ca3",
      "7cd5aa8a-b2b6-4c75-9fd1-447a96f8f303",
      "867b6eea-0b95-4a48-84e3-960eca540521",
      "e56a47a0-9dcb-413a-85ab-fa9980b3aa63",
      "ff1a3eae-3daa-4167-a702-1898f32721ab",
      "dc730dcb-1dd4-49b9-a4f3-ade344ec9375",
      "6cf95b83-c086-4dc0-952e-3e7ecd49c99a",
      "1097b6e6-db1a-45e6-8b6e-3ac4cd0dc5c4",
      "b5eb055d-bbfe-4f92-b207-7ac713a56d7f",
      "95fc0e9e-4b9e-4465-962f-40eeed3366e3",
      "66c108d8-08a4-457c-9ece-860e053ee37e",
      "8c77f9bb-21c5-42a0-8204-9ce1b01f3bd9",
      "2aaec76f-0858-4b30-80b7-c3877c8e569e",
      "f38b598f-7852-4a9f-9381-7f76a18d4fd3",
      "0eb42985-7ed8-4c6e-b546-35edf0689ce9",
      "ec509495-604d-4b29-a865-abc7a1b83625",
      "9015e662-2ce0-4921-81b7-0cc8fa942c8d",
      "fa688f51-3fc1-4ba2-b4e0-0cbb2881107e",
      "5665f849-c846-4e20-9396-85c9963b2f12",
      "809dc1c9-177e-438a-8d00-09fb10698481",
      "4fc8784b-e38c-452b-abc4-f48fc21ebca3",
      "5900a57d-6391-44b5-b5cb-6c73c9096eb7",
      "d52b21c6-fba3-4a82-aae9-64ed3dcb6b1d",
      "b0353058-a4e3-4086-bf7a-35f75e0a7ea2",
      "78e0ec9b-e103-4909-a391-499a7143b34b",
      "c970c404-8025-452f-afe9-c7cac002b047",
      "eabe3d14-0e3c-4186-bf48-6c6ed11c58a7",
    ]

    ContentItem.where(publishing_app: "publisher", content_id: welsh_content_ids).order(user_facing_version: "asc").each do |c|
      c.update!(locale: 'cy')
    end

    Commands::V2::RepresentDownstream.new.call(welsh_content_ids, true)
  end
end
