require 'rails_helper'

RSpec.describe RegisterableRedirect, :type => :model do
  let(:factory_name) { :registerable_redirect }

  context "for a prefix redirect" do
    it 'validates destination is an absolute path' do
      route = build(:registerable_redirect, :type => "prefix", :destination => 'not-absolute-path')

      expect(route).to_not be_valid
      expect(route.errors[:destination].size).to eq(1)
    end
  end

  context "for an exact redirect" do
    let(:redirect) { build(:registerable_redirect, :type => "exact") }

    it "is valid with an absolute path with optional query string and fragment" do
      [
        '/foo/bar',
        '/foo?bar=baz',
        '/foo/bar#baz',
      ].each do |dest|
        redirect.destination = dest
        expect(redirect).to be_valid, "expected redirect to be valid with destination: '#{dest}'"
      end
    end

    it "is invalid with an invalid or non-absolute URL" do
      [
        'foo/bar',
        '/url with spaces',
        'fdjkdfjkljsdaf',
      ].each do |dest|
        redirect.destination = dest
        expect(redirect).not_to be_valid, "expected redirect not to be valid with destination: '#{dest}'"
        expect(redirect.errors[:destination].size).to eq(1)
      end
    end

    it "is invalid with an external URL" do
      [
        'https://www.example.com/foo/bar',
        'https://www.gov.uk/foo/bar',
      ].each do |dest|
        redirect.destination = dest
        expect(redirect).not_to be_valid, "expected redirect not to be valid with destination: '#{dest}'"
        expect(redirect.errors[:destination].size).to eq(1)
      end
    end
  end
end
