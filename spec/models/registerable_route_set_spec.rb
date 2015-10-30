require 'rails_helper'

RSpec.describe RegisterableRouteSet, :type => :model do
  describe '.from_content_item' do
    it "constructs a route set from a non-redirect content item" do
      item = FactoryGirl.build(
        :draft_content_item,
        base_path: "/path",
        rendering_app: "frontend",
        routes: [
          { path: '/path', type: 'exact'},
          { path: '/path.json', type: 'exact'},
          { path: '/path/subpath', type: 'prefix'},
        ],
        redirects: []
      )
      route_set = RegisterableRouteSet.from_content_item(item)

      expect(route_set.is_redirect).to eq(false)
      expect(route_set.is_gone).to eq(false)
      expected_routes = [
        RegisterableRoute.new(:path => '/path',         :type => 'exact'),
        RegisterableRoute.new(:path => '/path.json',    :type => 'exact'),
        RegisterableRoute.new(:path => '/path/subpath', :type => 'prefix'),
      ]
      expect(route_set.registerable_routes).to match_array(expected_routes)
      expect(route_set.registerable_redirects).to eq([])
    end

    it "constructs a route set from a redirect content item" do
      item = build(:redirect_draft_content_item, :base_path => "/path")
      item.redirects = [
        { path: "/path", type: 'exact', destination: "/somewhere" },
        { path: "/path/foo", type: "prefix", destination: "/somewhere-else" },
      ]

      route_set = RegisterableRouteSet.from_content_item(item)
      expect(route_set.is_redirect).to eq(true)
      expect(route_set.registerable_routes).to eq([])
      expected_redirects = [
        RegisterableRedirect.new(:path => "/path", :type => "exact", :destination => "/somewhere"),
        RegisterableRedirect.new(:path => "/path/foo", :type => "prefix", :destination => "/somewhere-else"),
      ]
      expect(route_set.registerable_redirects).to match_array(expected_redirects)
    end

    it "constructs a route set from a gone content item" do
      item = build(:gone_draft_content_item, :base_path => "/path")
      item.routes = [
        { path: '/path', type: 'exact'},
        { path: '/path.json', type: 'exact'},
        { path: '/path/subpath', type: 'prefix'},
      ]

      route_set = RegisterableRouteSet.from_content_item(item)
      expect(route_set.is_gone).to eq(true)
      expected_routes = [
        RegisterableGoneRoute.new(:path => '/path',         :type => 'exact'),
        RegisterableGoneRoute.new(:path => '/path.json',    :type => 'exact'),
        RegisterableGoneRoute.new(:path => '/path/subpath', :type => 'prefix'),
      ]
      expect(route_set.registerable_routes).to match_array(expected_routes)
      expect(route_set.registerable_redirects).to eq([])
    end
  end

  describe "validations" do
    context "for a non-redirect item" do
      before :each do
        @route_set = build(:registerable_route_set, :is_redirect => false)
      end

      it 'is valid with a valid set of registerable routes' do
        @route_set.registerable_routes = [
          RegisterableRoute.new(:path => "#{@route_set.base_path}", :type => 'exact'),
          RegisterableRoute.new(:path => "#{@route_set.base_path}.json", :type => 'exact'),
          RegisterableRoute.new(:path => "#{@route_set.base_path}/exact-subpath", :type => 'exact'),
          RegisterableRoute.new(:path => "#{@route_set.base_path}/sub/path-prefix", :type => 'prefix'),
        ]
        expect(@route_set).to be_valid
      end

      it "requires some routes" do
        @route_set.registerable_routes = []
        expect(@route_set).not_to be_valid
        expect(@route_set.errors[:registerable_routes].size).to eq(1)
      end

      it "requires all routes to have a unique path" do
        @route_set.registerable_routes << build(:registerable_route, :path => @route_set.base_path)

        expect(@route_set).not_to be_valid
        expect(@route_set.errors[:registerable_routes].size).to eq(1)
      end

      it "requires the routes to include the base path" do
        @route_set.registerable_routes.first.path = "#{@route_set.base_path}/foo"
        expect(@route_set).to_not be_valid
        expect(@route_set.errors[:registerable_routes].size).to eq(1)
      end

      it "does not require a supplimentary route set to include the base path" do
        @route_set.registerable_routes.first.path = "#{@route_set.base_path}/foo"
        @route_set.is_supplimentary_set = true
        expect(@route_set).to be_valid
      end

      context "a non-redirect item that includes some redirects" do
        it "is valid with routes and redirects" do
          @route_set.registerable_redirects << build(:registerable_redirect, :path => @route_set.base_path + ".json")
          expect(@route_set).to be_valid
        end

        it "does not allow redirects to duplicate any of the routes" do
          @route_set.registerable_redirects << build(:registerable_redirect, :path => @route_set.base_path)
          expect(@route_set).not_to be_valid
          expect(@route_set.errors[:registerable_redirects].size).to eq(1)
        end
      end
    end

    context "for a redirect item" do
      before :each do
        @route_set = build(:registerable_route_set, :is_redirect => true)
      end

      it 'is valid with a valid set of registerable redirects' do
        @route_set.registerable_redirects = [
          RegisterableRedirect.new(:path => "#{@route_set.base_path}", :type => 'exact', :destination => "/somewhere"),
          RegisterableRedirect.new(:path => "#{@route_set.base_path}.json", :type => 'exact', :destination => "/somewhere"),
          RegisterableRedirect.new(:path => "#{@route_set.base_path}/exact-subpath", :type => 'exact', :destination => "/somewhere"),
          RegisterableRedirect.new(:path => "#{@route_set.base_path}/sub/path-prefix", :type => 'prefix', :destination => "/somewhere"),
        ]
        expect(@route_set).to be_valid
      end

      it "requires no routes to be present" do
        @route_set.registerable_routes = [build(:registerable_route, :path => @route_set.base_path)]
        expect(@route_set).not_to be_valid
        expect(@route_set.errors[:registerable_routes].size).to eq(1)
      end

      it "requires all redirects to have a unique path" do
        @route_set.registerable_redirects << build(:registerable_redirect, :path => @route_set.base_path)

        expect(@route_set).not_to be_valid
        expect(@route_set.errors[:registerable_redirects].size).to eq(1)
      end

      it "requires the redirects to include the base path" do
        @route_set.registerable_redirects.first.path = "#{@route_set.base_path}/foo"
        expect(@route_set).to_not be_valid
        expect(@route_set.errors[:registerable_redirects].size).to eq(1)
      end
    end
  end
end
