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

    it "must have a valid type" do
      subject.routes = [{ path: subject.base_path, type: "unsupported" }]
      expect(subject).to be_invalid
    end

    it "cannot have extra keys" do
      subject.routes = [{ path: subject.base_path, type: "exact", foo: "bar" }]

      expect(subject).to be_invalid
      expect(subject.errors[:routes]).to eq(["are invalid"])
    end

    it "is valid with a dashed locale" do
      subject.routes = [
        { path: subject.base_path, type: "exact" },
        { path: "#{subject.base_path}.es-419", type: "exact" },
      ]

      expect(subject).to be_valid
    end

    context "for a redirect item" do
      before do
        subject.format = "redirect"
        subject.routes = []
      end

      it "can have redirects" do
        subject.redirects = [{ path: subject.base_path, type: "exact", destination: "/foo" }]
        expect(subject).to be_valid
      end
    end

    context "for a non-redirect item" do
      before do
        subject.format = "guide"
      end

      it "can have redirects" do
        subject.redirects = [{ path: "#{subject.base_path}/foo", type: "exact", destination: "/foo" }]
        expect(subject).to be_valid
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
      expect(subject.errors[:redirects]).to eq(["are invalid"])
    end

    it "is valid with a dashed locale" do
      subject.redirects = [{ path: "#{subject.base_path}.es-419", type: "exact", destination: "/foo" }]
      expect(subject).to be_valid
    end

    context "for a redirect item" do
      before do
        subject.format = "redirect"
      end

      it "must not have routes" do
        subject.routes = [{ path: subject.base_path, type: "exact" }]
        expect(subject).to be_invalid
      end
    end

    context "for a non-redirect item" do
      before do
        subject.format = "guide"
      end

      it "can have routes" do
        subject.routes = [{ path: subject.base_path, type: "exact" }]
        expect(subject).to be_valid
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
