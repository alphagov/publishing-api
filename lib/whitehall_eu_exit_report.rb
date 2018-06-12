require "fileutils"

class WhitehallEuExitReport
  def self.call(*args)
    new(*args).call
  end

  def initialize(path:)
    @path = path
  end

  def call
    FileUtils::mkdir_p(path)
  end

  private_class_method :new

private

  EU_EXIT_TAXONS = [
    "21eee04d-e702-4e7b-9fde-2f6777f1be2c", # business / business and enterprise
    "ed2ca1f7-5463-4eda-9324-b597e269e242", # business / trade and investment
    "4ef6d013-ec2d-4ae8-a1a0-5a984e6e6c42", # business / media and communications
    "da0bc015-f8e5-492c-8d81-6fbf9b18947c", # business / consumer rights and issues
    "35f5b496-add7-4263-8084-8510461881fe", # business / employing people
    "ccb77bcc-56b4-419a-b5ce-f7c2234e0546", # business / science and innovation
    "a1e4659c-dc15-48be-bc4f-6c609ae061dc", # business / uk economy
    "cb4c8377-6fcb-4022-a7a1-98395eb50508", # business / water industry

    "dd767840-363e-43ad-8835-c9ab516633de", # education / funding and higher education skills and vocational training
    "ff00b8b2-dcdb-4659-93c2-291c9be354f3", # education / teaching and leadership
    "23265b25-7ec3-4960-8517-4ff8d4d92cac", # education / funding and finance for students

    "6e85c12f-f52b-41b3-93ad-59e5f19d64f6", # entering and staying in the uk / rights of foreign nationals in the uk
    "18c7918f-cde5-4e66-b5f4-cd15c33cc1cc", # entering and staying in the uk / travel and identity documents for foreign nationals
    "c64eb759-93ff-4bfd-86f2-16753fc1e062", # entering and staying in the uk / immigration rules
    "29480b00-dc4d-49a0-b48c-25dda8569325", # entering and staying in the uk / visas and entry clearance
    "262e9ea7-90fc-4ac8-8aa7-fc294282a1d4", # entering and staying in the uk / border control
    "fa13521f-9285-45b0-bd65-4a472a8037e7", # entering and staying in the uk / immigration offences
    "fef7e737-6f1a-4ef4-b844-aa24b630ad03", # entering and staying in the uk / permanant stay in the uk
    "08a8a69f-2825-4fe2-a4cf-c83458a5629e", # entering and staying in the uk / refugee asylum and human rights

    "b14a6778-60a2-483a-924c-774d1040cbf4", # environment / commercial fishing and fisheries
    "52ff5c99-a17b-42c4-a9d7-2cc92cccca39", # environment / food and farming
    "42fdd045-cadf-474b-b8a6-ca20a77c43bb", # environment / marine
    "1218dda2-9279-4fec-840c-1321cb1a8934", # environment / oil and gas
    "d304dcea-c3f6-4b56-859c-6409a8712111", # environment / wildlife and animal welfare
    "2368b8b1-9405-4e66-b396-a5d54b777a0a", # environment / farming and food grants and payments

    "d96e4efc-9c26-4d9b-9fa7-a036b5c11a65", # going and being abroad / travel abroad
    "27b9c5cd-b390-4332-89be-73491df35a41", # going and being abroad / passports
    "ce9e9802-6138-4fe9-9f33-045ef213be29", # going and being abroad / countries (living in)

    "d6c2de5d-ef90-45d1-82d4-5f2438369eea", # government / brexit

    "d69977ab-4fb1-4ad6-b379-e967c5b7528b", # health and social care / disabled people
    "30ba2d05-d0d6-4978-a5d6-707511894111", # health and social care / health protection
    "7d67047c-bf22-4c34-b566-b46d6973f961", # health and social care / social care

    "cefad480-c674-46c9-8bd6-8d71beb3e372", # housing, local and community / noise, neighbours, pets and pests

    "3dbeb4a3-33c0-4bda-bd21-b721b0f8736f", # international / british nationals overseas
    "d956c72a-246d-4787-af39-00bf58b2ea66", # international / living abroad

    "a5c88a77-03ba-4100-bd33-7ee2ce602dc8", # money / personal tax

    "a44b1c68-807c-45fe-bc7b-a47586617863", # parenting, childcare and childrens services / financial help if you have children

    "b29cf14b-54c6-402c-a9f0-77218602d1af", # society and culture / arts and culture

    "84a394d2-b388-4e4e-904e-136ca3f5dd7d", # transport / driving and road transport
    "51efa3dd-e9bc-42b2-aa26-06bf5f543015", # transport / aviation
    "3e4df71e-474d-4a40-bd6a-b3072affa151", # transport / freight and cargo
    "4a9ab4d7-0d03-4c61-9e16-47787cbf53cd", # transport / maritime and shipping
    "13d01427-33b5-4ca4-bf7a-68425f54e236", # transport / rail
    "3767d89c-b00c-431e-8b0b-b91c8ff26238", # transport / transport training and careers

    "536f83c0-8c67-47a3-88a4-d5b1eda591ed", # welfare / benefits entitlement
    "29dbee2a-5865-489b-860f-7eef54a5165a", # welfare / benefits for families
    "05a9527b-e6e9-4a68-8dd7-7d84e6a24eef", # welfare / carers and disability benefits
    "7a1ba896-b85a-4137-81d9-ab05b7ce67dd", # welfare / child benefit (welfare theme)
    "ac7b8472-5d09-4679-9551-87847b0ac827", # welfare / death and benefits
    "2a1bd1b1-5025-4313-9e5b-8352dd46f1d6", # welfare / jobseekers allowance and low income benefits
    "a7f3005b-a3cd-4060-a127-725accb54f2e", # welfare / tax credits
    "62fcbba5-3a75-4d15-85a6-d8a80b03d57c", # welfare / universal credit
    "6c4c443c-2e11-4d25-aa93-2e3a38d9499c", # welfare / heating and housing benefits

    "092348a4-b896-4f8f-a0dc-e6d4605a4904", # work / working, jobs and pensions
  ].freeze

  attr_reader :path
end
