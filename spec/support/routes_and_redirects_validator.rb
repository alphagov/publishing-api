RSpec.shared_examples_for RoutesAndRedirectsValidator do
  describe "routes validations" do
    it "is invalid when a route is not below the base path" do
      subject.routes = [
        { path: subject.base_path, type: "exact" },
        { path: "/wrong-path", type: "exact" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["path must be below the base path"])
    end

    it "must have unique paths" do
      subject.routes = [
        { path: subject.base_path, type: "exact" },
        { path: subject.base_path, type: "exact" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["must have unique paths"])
    end

    it "must have a type" do
      subject.routes = [{ path: subject.base_path }]
      expect(subject).to be_invalid
    end

    it "must have a path" do
      subject.routes = [{ type: "exact" }]
      expect(subject).to be_invalid
    end

    it "must have a valid type" do
      subject.routes = [{ path: subject.base_path, type: "unsupported" }]
      expect(subject).to be_invalid
    end

    it "cannot have extra keys" do
      subject.routes = [{ path: subject.base_path, type: "exact", foo: "bar" }]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["unsupported keys: foo"])
    end

    it "is valid with a dashed locale" do
      subject.routes = [
        { path: subject.base_path, type: "exact" },
        { path: "#{subject.base_path}.es-419", type: "exact" },
      ]

      expect(subject).to be_valid
    end

    it "must contain valid absolute paths" do
      subject.routes = [
        { path: subject.base_path, type: "exact" },
        { path: "#{subject.base_path}/ not valid", type: "exact" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["is not a valid absolute URL path"])
    end

    it "does not throw an error when routes is nil rather than an empty array" do
      subject.routes = nil
      expect { subject.valid? }.to_not raise_error
    end

    context "for a redirect item" do
      before do
        subject.format = "redirect"
        subject.routes = []
      end

      it "must not have routes" do
        subject.routes = [{ path: "#{subject.base_path}/foo", type: "exact" }]
        expect(subject).to be_invalid
      end
    end

    context "for a non-redirect item" do
      before do
        subject.format = "guide"
      end

      it "must have routes" do
        subject.routes = [{ path: subject.base_path, type: "exact" }]
        expect(subject).to be_valid
      end

      it "must include the base path" do
        subject.routes = [{ path: "#{subject.base_path}/foo", type: "exact" }]
        expect(subject).to be_invalid
      end

      it "does not throw an error when routes is nil rather than an empty array" do
        subject.routes = nil
        expect { subject.valid? }.to_not raise_error
      end
    end
  end

  describe "redirects validations" do
    it "is invalid when a redirect is not below the base path" do
      subject.redirects = [
        { path: "/wrong-path", type: "exact", destination: "/bar" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:redirects]).to eq(["path must be below the base path"])
    end

    it "must have unique paths" do
      subject.redirects = [
        { path: "#{subject.base_path}/foo", type: "exact", destination: "/bar" },
        { path: "#{subject.base_path}/foo", type: "exact", destination: "/bar" },
      ]

      expect(subject).to be_invalid
      expect(subject.errors[:redirects]).to eq(["must have unique paths"])
    end

    it "must have a valid type" do
      subject.redirects = [{ path: subject.base_path, type: "unsupported", destination: "/foo" }]
      expect(subject).to be_invalid
    end

    it "cannot have extra keys" do
      subject.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: "/foo", foo: "bar" }]

      expect(subject).to be_invalid
      expect(subject.errors[:redirects]).to eq(["unsupported keys: foo"])
    end

    it "is valid with a dashed locale" do
      subject.redirects = [{ path: "#{subject.base_path}.es-419", type: "exact", destination: "/foo" }]
      expect(subject).to be_valid
    end

    it "must contain valid absolute paths" do
      subject.redirects = [{ path: "#{subject.base_path}/ not valid", type: "exact", destination: "/foo" }]

      expect(subject).to be_invalid
      expect(subject.errors[:redirects]).to eq(["is not a valid absolute URL path"])
    end

    it "does not throw an error when redirects is nil rather than an empty array" do
      subject.redirects = nil
      expect { subject.valid? }.to_not raise_error
    end

    context "when the type is 'prefix'" do
      it "must contain valid absolute paths for destinations" do
        subject.redirects = [{ path: "#{subject.base_path}/foo", type: "prefix", destination: "not valid" }]

        expect(subject).to be_invalid
        expect(subject.errors[:redirects]).to eq(["is not a valid absolute URL path"])
      end
    end

    context "when the type is 'exact'" do
      it "is valid with an optional query string and fragment in destination" do
        %w(/foo/bar /foo?bar=baz /foo/bar#baz).each do |destination|
          subject.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: destination }]
          expect(subject).to be_valid
        end
      end

      it "is invalid with an non-absolute url" do
        ["foo/bar", "/url with spaces", "fdjkdfjkljsdaf"].each do |destination|
          subject.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: destination }]

          expect(subject).to be_invalid
          expect(subject.errors[:redirects]).to eq(["is not a valid redirect destination"])
        end
      end

      it "is invalid with an external url" do
        ["https://www.example.com/foo/bar", "https://www.gov.uk/foo/bar"].each do |destination|
          subject.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: destination }]

          expect(subject).to be_invalid
          expect(subject.errors[:redirects]).to eq(["is not a valid redirect destination"])
        end
      end
    end

    context "for a redirect item" do
      before do
        subject.format = "redirect"
        subject.routes = []
      end

      it "must have redirects" do
        subject.redirects = [{ path: subject.base_path, type: "exact", destination: "/foo" }]
        expect(subject).to be_valid
      end

      it "must include the base path" do
        subject.redirects = [{ path: "#{subject.base_path}/bar", type: "exact", destination: "/bar" }]
        expect(subject).to be_invalid
      end
    end

    context "for a non-redirect item" do
      before do
        subject.format = "guide"
      end

      it "can have redirects" do
        subject.redirects = [{ path: "#{subject.base_path}/bar", type: "exact", destination: "/bar" }]
        expect(subject).to be_valid
      end

      it "does not throw an error when redirects is nil rather than an empty array" do
        subject.redirects = nil
        expect { subject.valid? }.to_not raise_error
      end
    end
  end

  describe "validations that cross-over between routes and redirects" do
    it "does not allow redirects to duplicate any of the routes" do
      subject.routes = [{ path: subject.base_path, type: "exact" }]
      subject.redirects = [{ path: subject.base_path, type: "exact", destination: "/foo" }]

      expect(subject).to be_invalid
    end
  end
end
