RSpec.shared_examples_for RoutesAndRedirectsValidator do
  describe "routes validations" do
    it "is invalid when a route is not below the base path" do
      edition.routes = [
        { path: subject.base_path, type: "exact" },
        { path: "/wrong-path", type: "exact" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["path must be below the base path"])
    end

    it "is valid when a route has a document type suffix" do
      edition.routes = [
        { path: subject.base_path, type: "exact" },
        { path: "#{subject.base_path}.atom", type: "exact" },
      ]

      expect(subject).to be_valid
    end

    describe "with nested translated routes" do
      let(:edition) { build(:edition, base_path: "/vat-rates.fr") }

      it "is valid when a translated route is below the base path" do
        edition.routes = [
          { path: "/vat-rates.fr", type: "exact" },
          { path: "/vat-rates/path/document.fr", type: "exact" },
        ]

        expect(subject).to be_valid
      end

      it "is invalid when a translated route is below the base path but has the wrong translation" do
        edition.routes = [
          { path: "/vat-rates.fr", type: "exact" },
          { path: "/vat-rates/path/document.fr", type: "exact" },
          { path: "/vat-rates/path/document.es", type: "exact" },
        ]

        expect(subject).to be_invalid
        expect(subject.errors[:routes]).to eq(["path must be below the base path"])
      end
    end

    it "must have unique paths" do
      edition.routes = [
        { path: subject.base_path, type: "exact" },
        { path: subject.base_path, type: "exact" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["must have unique paths"])
    end

    it "must have a type" do
      edition.routes = [{ path: subject.base_path }]
      expect(subject).to be_invalid
    end

    it "must have a path" do
      edition.routes = [{ type: "exact" }]
      expect(subject).to be_invalid
    end

    it "must have a valid type" do
      edition.routes = [{ path: subject.base_path, type: "unsupported" }]
      expect(subject).to be_invalid
    end

    it "cannot have extra keys" do
      edition.routes = [{ path: subject.base_path, type: "exact", foo: "bar" }]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["unsupported keys: foo"])
    end

    it "is valid with a dashed locale" do
      edition.routes = [
        { path: subject.base_path, type: "exact" },
        { path: "#{subject.base_path}.es-419", type: "exact" },
      ]

      expect(subject).to be_valid
    end

    it "must contain valid absolute paths" do
      edition.routes = [
        { path: subject.base_path, type: "exact" },
        { path: "#{subject.base_path}/ not valid", type: "exact" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["is not a valid absolute URL path"])
    end

    it "does not throw an error when routes is nil rather than an empty array" do
      edition.routes = nil
      expect { subject.valid? }.to_not raise_error
    end

    context "for a redirect item" do
      before do
        edition.document_type = "redirect"
        edition.routes = []
      end

      it "must not have routes" do
        edition.routes = [{ path: "#{subject.base_path}/foo", type: "exact" }]
        expect(subject).to be_invalid
      end
    end

    context "for a non-redirect item" do
      before do
        edition.document_type = "nonexistent-schema"
      end

      it "must have routes" do
        edition.routes = [{ path: subject.base_path, type: "exact" }]
        expect(subject).to be_valid
      end

      it "must include the base path" do
        edition.routes = [{ path: "#{subject.base_path}/foo", type: "exact" }]
        expect(subject).to be_invalid
      end

      it "does not throw an error when routes is nil rather than an empty array" do
        edition.routes = nil
        expect { subject.valid? }.to_not raise_error
      end
    end
  end

  describe "redirects validations" do
    it "is invalid when a redirect is not below the base path" do
      edition.redirects = [
        { path: "/wrong-path", type: "exact", destination: "/bar" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:redirects]).to eq(["path must be below the base path"])
    end

    it "must have unique paths" do
      edition.redirects = [
        { path: "#{subject.base_path}/foo", type: "exact", destination: "/bar" },
        { path: "#{subject.base_path}/foo", type: "exact", destination: "/bar" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:redirects]).to eq(["must have unique paths"])
    end

    it "must have a valid type" do
      edition.redirects = [{ path: subject.base_path, type: "unsupported", destination: "/foo" }]
      expect(subject).to be_invalid
    end

    it "cannot have extra keys" do
      edition.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: "/foo", foo: "bar" }]

      expect(subject).to be_invalid
      expect(subject.errors[:redirects]).to eq(["unsupported keys: foo"])
    end

    it "is valid with a dashed locale" do
      edition.redirects = [{ path: "#{subject.base_path}.es-419", type: "exact", destination: "/foo" }]
      expect(subject).to be_valid
    end

    it "must contain valid absolute paths" do
      edition.redirects = [{ path: "#{subject.base_path}/ not valid", type: "exact", destination: "/foo" }]

      expect(subject).to be_invalid
      expect(subject.errors[:redirects]).to eq(["is not a valid absolute URL path"])
    end

    it "does not throw an error when redirects is nil rather than an empty array" do
      edition.redirects = nil
      expect { subject.valid? }.to_not raise_error
    end

    context "when destination is a internal url" do
      it "is invalid if it ends with /" do
        edition.redirects = [
          {
            path: "#{subject.base_path}/foo",
            type: "exact",
            destination: "#{subject.base_path}/bar/",
          },
        ]
        expect(subject).to be_invalid
      end

      it "is valid when it redirects to the homepage" do
        edition.redirects = [
          {
            path: "#{subject.base_path}/foo",
            type: "exact",
            destination: "/",
          },
        ]
        expect(subject).to be_valid
      end
    end

    context "when destination is external url" do
      it "is invalid if it is not actually an external url" do
        ["https://gov.uk/test", "https://www.gov.uk/foo/bar"].each do |destination|
          edition.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: }]

          expect(subject).to be_invalid
        end
      end

      it "is invalid if the url is a malformed gov.uk external url" do
        %w[
          ://new-vat-rates.campaign.gov.uk/
          http:new-vat-rates.campaign.gov.uk/
          httpsnew-vat-rates.campaign.gov.uk/
          https://new_vat-rates.campaign.gov.uk/
          http://.campaign.gov.uk/
          http://new-vat-rates.campaign.gov.uk/path/to/your/new/vat-rates
          http://new-vat-rates.campaignjservicepgov.uk/path/to/your/new/vat-rates
          https://fakesite.net/.new-vat-rates.campaign.gov.uk/path/to/your/new/vat-rates
          ftp://new-vat-rates.campaign.gov.uk/
          https://evilgov.uk/
        ].each do |destination|
          edition.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: }]

          expect(subject).to be_invalid
        end
      end

      it "is valid if the url is a wellformed gov.uk external url" do
        %w[
          https://www.pointsoflight.gov.uk/
          https://www.cloud.service.gov.uk/
          https://new-vat-rates.campaign.gov.uk/
          https://new-vat-rates.campaign.gov.uk/path/to/your/new/vat-rates
          https://new-vat-rates.campaign.gov.uk/path/to/your/new/vat-rates?q=123&&a=23344
          https://www.judiciary.uk/
          https://etl.beis.gov.uk/
          https://www.nhs.uk/
          https://www.ukri.org/
          https://nationalhighways.co.uk/
          https://www.nationalhighways.co.uk/
          https://www.police.uk/
        ].each do |destination|
          edition.redirects = [{ path: "#{subject.base_path}/new", type: "exact", destination: }]

          expect(subject).to be_valid
          expect(subject.errors[:redirects]).to eq([])
        end
      end
    end

    context "when the segments_mode is 'preserve'" do
      it "must not contain query parameters in the destination" do
        edition.redirects = [
          {
            path: "#{subject.base_path}/foo",
            type: "exact",
            segments_mode: "preserve",
            destination: "/bar?baz=4",
          },
        ]

        expect(subject).to be_invalid
      end

      it "must not contain a fragment in the destination" do
        edition.redirects = [
          {
            path: "#{subject.base_path}/foo",
            type: "prefix",
            segments_mode: "preserve",
            destination: "/bar#baz",
          },
        ]

        expect(subject).to be_invalid
      end
    end

    context "when the type is 'prefix'" do
      it "must contain valid absolute paths for destinations" do
        edition.redirects = [{ path: "#{subject.base_path}/foo", type: "prefix", destination: "not valid" }]

        expect(subject).to be_invalid
      end
    end

    context "when the type is 'exact'" do
      it "is valid with an optional query string and fragment in destination" do
        %w[/foo/bar /foo?bar=baz /foo/bar#baz].each do |destination|
          edition.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: }]
          expect(subject).to be_valid
        end
      end

      it "is invalid with an non-absolute url" do
        ["foo/bar", "/url with spaces", "fdjkdfjkljsdaf"].each do |destination|
          edition.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: }]

          expect(subject).to be_invalid
        end
      end
    end

    context "for a redirect item" do
      before do
        edition.schema_name = "redirect"
        edition.document_type = "redirect"
        edition.routes = []
      end

      it "must have redirects" do
        edition.redirects = [{ path: subject.base_path, type: "exact", destination: "/foo" }]
        expect(subject).to be_valid
      end

      it "must include the base path" do
        edition.redirects = [{ path: "#{subject.base_path}/bar", type: "exact", destination: "/bar" }]
        expect(subject).to be_invalid
      end
    end

    context "for a non-redirect item" do
      before do
        edition.document_type = "nonexistent-schema"
      end

      it "can have redirects" do
        edition.redirects = [{ path: "#{subject.base_path}/bar", type: "exact", destination: "/bar" }]
        expect(subject).to be_valid
      end

      it "does not throw an error when redirects is nil rather than an empty array" do
        edition.redirects = nil
        expect { subject.valid? }.to_not raise_error
      end
    end
  end

  describe "validations that cross-over between routes and redirects" do
    it "does not allow redirects to duplicate any of the routes" do
      edition.routes = [{ path: subject.base_path, type: "exact" }]
      edition.redirects = [{ path: subject.base_path, type: "exact", destination: "/foo" }]

      expect(subject).to be_invalid
    end
  end
end
