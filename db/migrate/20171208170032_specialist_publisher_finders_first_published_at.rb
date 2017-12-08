require "csv"
require_relative "helpers/february29th2016"

class SpecialistPublisherFindersFirstPublishedAt < ActiveRecord::Migration[5.1]
  def up
    content_ids_to_date = [
      # /aaib-reports
      ["b7574bba-969f-4c49-855a-ae1586258ff6", "2015-09-03T14:47:48Z"],
      # /asylum-support-tribunal-decisions
      ["581b4bba-e58f-4d07-8e0a-03c8c00165cc", "2017-02-08T16:15:13Z"],
      ["307ea825-594c-4d88-85c9-0809fdc9c79e", "2017-02-08T16:15:13Z"],
      # /business-finance-support
      ["12fecc5b-c02a-405e-b96e-7aa32ceaf504", "2017-03-20T10:23:48Z"],
      ["32e87f32-8e37-4186-bc0c-fbed4c0f0239", "2017-03-20T10:23:48Z"],
      # /cma-cases
      ["fef4ac7c-024a-4943-9f19-e85a8369a1f3", "2015-08-17T13:28:37Z"],
      ["43dd2b13-93ec-4ca6-a7a4-e2eb5f5d485a", "2015-08-17T13:28:37Z"],
      # /countryside-stewardship-grants
      ["0eb7b150-879a-4c44-becc-718e23a77e2c", "2015-08-17T13:28:37Z"],
      # /dfid-research-outputs
      ["af7c7cdb-1335-4f1c-b21c-b3c8bfec8a1b", "2016-08-02T13:57:19Z"],
      ["a062704c-f49d-4942-aaf4-c06d81ada3b8", "2016-08-02T13:57:20Z"],
      # /drug-safety-update
      ["602be505-4cf4-4f8c-8bfc-7bc4b63a7f47", "2015-08-17T13:28:37Z"],
      ["ccf11f55-02ee-48ec-b71c-7e3fe78b3a17", "2015-08-17T13:28:37Z"],
      # /employment-appeal-tribunal-decisions
      ["975cf540-6e64-40e3-b62a-df655a8c99ef", "2017-03-15T14:48:55Z"],
      ["1f5911f4-417a-4380-a5a0-674ebff332df", "2017-03-15T14:48:55Z"],
      # /employment-tribunal-decisions
      ["1b5e08c8-ddde-4637-9375-f79e085ba6d5", "2017-02-08T16:15:17Z"],
      ["6d7ace06-f437-4fb3-b948-8534ff34540f", "2017-02-08T16:15:17Z"],
      # /european-structural-investment-funds
      ["78cedbfe-d3aa-41c3-b8c0-aeb5d9035d6a", "2016-01-08T14:30:23Z"],
      ["a4815714-e5d5-4e1b-8543-3ce10139988f", "2016-01-08T14:30:23Z"],
      # /international-development-funding
      ["5583057c-7c57-4cfe-b70d-dad6f4762831", "2015-08-17T13:28:37Z"],
      ["f1a4e5b2-c8b3-40f2-acde-75061a45184d", "2015-08-17T13:28:37Z"],
      # /maib-reports
      ["33eb214a-9291-49d3-8789-445c1e97b586", "2015-08-17T13:28:37Z"],
      ["56cb57e2-7e7f-4f67-b2f6-39c9a55385dc", "2015-08-17T13:28:37Z"],
      # /drug-device-alerts
      ["1e9c0ada-5f7e-43cc-a55f-cc32757edaa3", "2015-10-16T11:07:17Z"],
      ["a796ca43-021b-4960-9c99-f41bb8ef2266", "2015-10-16T11:07:17Z"],
      # /raib-reports
      ["e3ff7fc5-6788-45de-83f0-cbf34e9fe8bd", "2015-08-17T13:28:37Z"],
      ["db81c7e8-b1b6-4c29-992a-1289f1b63073", "2015-08-17T13:28:37Z"],
      # /service-standard-reports
      ["da025a9f-8293-4fef-869c-12445d364696", "2016-12-19T15:02:57Z"],
      # /tax-and-chancery-tribunal-decisions
      ["632290ae-aad8-4895-b135-1e0a72a6bdeb", "2016-12-01T16:16:21Z"],
      ["ae5afec1-30d6-4997-bdf8-7de94d2dd910", "2016-12-01T16:16:21Z"],
      # /administrative-appeals-tribunal-decisions
      ["e9e7fcff-bb0d-4723-af25-9f78d730f6f8", "2016-12-01T16:16:20Z"],
      ["13e59efa-6c0d-48e8-a0b9-092b62cdc912", "2016-12-01T16:16:20Z"]
    ]
    Helpers::February29th2016.replace_first_published_at(
      content_ids_to_date,
      where_conditions: { publishing_app: "specialist-publisher" },
    )
  end
end
