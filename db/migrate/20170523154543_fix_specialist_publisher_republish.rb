class FixSpecialistPublisherRepublish < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  # This migration is to fix the results of running a republish in Specialist
  # Publisher which, due to update_type oddities, ends up setting a bunch of
  # key dates to nil
  def up
    scope.find_each do |edition|
      unless edition.last_edited_at
        edition.last_edited_at = maximum_last_edited_at(edition.document_id)
      end

      unless edition.public_updated_at
        edition.public_updated_at = maximum_public_updated_at(edition.document_id)
      end

      next unless edition.changed?

      edition.save
    end
  end

private

  def scope
    e = Edition.arel_table
    d = Document.arel_table

    Edition
      .with_document
      .includes(:document)
      .where(publishing_app: "specialist-publisher")
      .where.not(content_store: nil)
      .where("last_edited_at IS NULL OR public_updated_at IS NULL")
      .where(
        e[:document_type].eq("cma_case").or(
          d[:content_id].in(content_ids)
        )
      )
  end

  def maximum_last_edited_at(document_id)
    Edition.where(document_id: document_id).maximum(:last_edited_at)
  end

  def maximum_public_updated_at(document_id)
    Edition.where(document_id: document_id).maximum(:public_updated_at)
  end

  # These content ids were run as rake tasks in:
  # https://deploy.publishing.service.gov.uk/job/run-rake-task/1155/console
  # https://deploy.publishing.service.gov.uk/job/run-rake-task/1156/console
  def content_ids
    %w(
      46fb4dec-d076-473a-8c42-f24d03e04b30
      d98d7b87-309e-47b9-9467-4ca2ac9ffbe5
      0e060474-d37a-4480-a9fa-0af554b60114
      8e37c52f-3694-44f9-833b-263726923007
      32eb43d9-3e08-49d5-9674-b132c97a297b
      1cf6c2eb-13bf-4c09-9b44-10fa1587e8da
      8f2dabb8-dab2-4206-a549-897cf2cef91d
      8f2dabb8-dab2-4206-a549-897cf2cef91d
      c4a8940a-405c-4fd3-ad6b-3cb9eef47f9a
      c4a8940a-405c-4fd3-ad6b-3cb9eef47f9a
      eedefdd7-3feb-4f2d-be18-ce267fdc14e4
      4a9b4a0a-869a-49b9-83da-69ad6ac35960
      0ad29f08-ebd8-4b15-a6e0-c5aa9c484841
      f9935eb2-1adb-4e9a-bcff-d2e780b1dcf3
      6561603a-336b-4f50-b259-afda5116e9ac
      af171dcb-fa3b-4c93-b7d4-6f0af6c15601
      dd742684-b87e-4e89-803f-ef9d269bcf46
      c67f3666-1c84-4404-ae4a-5c2ad75b4542
      66d32246-eeeb-47c4-9761-c07e124dfcf0
      829f3286-3407-40cb-988f-44932337421a
      a0aba22c-e601-455f-b38d-3e93d3f847d6
      99fae780-6e98-49cf-97b4-52d178f4c9b8
      5aed715f-0353-4e6a-be27-ef09d8157e07
      e44435da-b02b-40a9-90ef-2c923f1025c8
      d5b9cdda-ec08-442d-a54d-c176682c49aa
      e611b6c0-f352-4652-9998-78af5a4c36b4
      10110f7d-5062-4b34-9f72-0cff65faa11e
      4d0099cd-9006-487c-b526-71e29bbb5055
      91e1282f-05f8-48bb-bb9c-ea3a79a327c0
      436f27e1-78d5-48d6-90f7-3caa221abb36
      dd7b004e-dbbd-4064-ab63-c7cbd5ab9cb6
      08dcd555-d18e-4a60-9178-2fcb63fa4bdb
      1c26d403-5c9c-47ea-96bf-aac8ee0d51cf
      0401ba66-4b07-431a-ad7a-db45a7c80aa1
      33c134dc-7c79-4e7c-88fa-398958bd1791
      061453df-80ca-4efc-9455-f80fef9f4e42
      1aa1a7c9-edd8-4429-ad19-ddd6bc60de6f
      b235e95f-6516-4d46-acaf-1b15013a2c55
      332b6e23-5205-4508-9b4c-8d8251df0ebe
      34e62cba-fe7d-4465-9bb0-c05636b4dca8
      ac353220-d0ef-4311-868a-6202fb1bfa78
      d8b7df0a-534a-4d14-a89d-5f1cb59c9d60
      055fb946-e789-4cdc-adc8-c43fcf2ba6a0
      fb5d845f-c1a3-429c-9014-e2baf58cf626
      de69b274-b822-4e52-8f18-ffb9c5eb9863
      ea5c99b0-7bf1-4ac2-9258-8e14b013afed
      ce4cf58d-f79c-421d-bae8-ecd9c8de024f
      9205a95b-ef26-4de9-b794-53868662cab9
      92e96ae3-921f-45d9-ac67-fbdff1e41744
      eb2f1283-39f0-45b6-aee0-95105c47e411
      ff08e410-37c4-4de8-bace-a0deb4434be6
      8f08c475-90f7-435d-9149-64db1badc9a6
      e96a0022-46c5-4436-883f-3526dad1a73e
      5bb609ca-5c68-42d0-9c80-9e3e0075d674
      b99ae902-0e41-4524-be35-4f9749d8cbe1
      160d3ab7-8aaa-428a-a847-fbae44a7e727
      3557e3ae-ffc4-488c-8917-e9d50b9bef40
      04ea06fb-21c1-4978-bd35-4aa9fd426642
      f964f2bc-69c2-422a-bd77-e970f4ff1220
      ce568c5b-929d-4c42-a920-1f966a9bcf0e
      69b190be-6d65-45dc-8ff8-9a5460616776
      e4f4ee0a-aef6-47d3-bca7-5f3f48e1313f
      7ab2ac17-5fb5-40c7-8a18-6debbeeacfe2
      f1faf6f0-d7b2-483d-8a05-fe35dde112d2
      1bc13f1f-d6cf-4dfe-8cd1-2bc5f8435266
      c036e51b-5759-4438-bf92-8267fc8d0506
      e9d9396c-d814-4a4f-a71f-0e2faff942eb
      dac2a79b-610b-4b2d-9ef9-98b0859519af
      b9a8c78a-6bd1-4d92-bb69-74f53f1896ac
      7ffb187b-f872-46e1-b919-60a330891bd7
      44da216f-fa44-4b28-a05c-264517b3cc20
      3a79650d-0f5c-401a-98ed-c81460e9686c
      191e875e-f2a2-4fbb-b4ff-7fcc643d6139
      c96889bd-7e2b-4741-9a54-658479541d6d
      6b4ee6e7-259f-40aa-939b-e629c7a8d2e1
      e7831dd4-52cf-4f49-adb7-620011237f4f
      43b3ab47-4dab-4668-8c2c-1645ce204ebc
      814ecad1-dad3-4a2b-9f53-582e800579a0
      c8a1f45d-f99a-46f7-8903-59b8a97ba773
      1f9795f2-7fe6-4b9b-b872-9918378d0d63
      186f306b-3554-4b35-934d-1d8e10cc9b34
      464e1a8b-9667-4fb2-b38a-17beb042141c
      0c1ecf7d-eb85-4847-acb8-e834be5d721d
      ce8aeb9a-5f5a-4f9b-917d-c3259da90ced
      3513fea1-2a8e-47e2-bd9f-87b0385895a1
      d98d7b87-309e-47b9-9467-4ca2ac9ffbe5
    )
  end
end
