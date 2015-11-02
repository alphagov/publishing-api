FactoryGirl.define do
  factory :registerable_route do
    skip_create

    path "/foo"
    type "prefix"
  end

  factory :registerable_gone_route, parent: :registerable_route, class: RegisterableGoneRoute

  factory :registerable_redirect do
    skip_create

    path "/foo"
    type "prefix"
    destination "/bar"
  end

  factory :registerable_route_set do
    skip_create

    base_path "/foo"
    rendering_app "frontend"

    after :build do |route_set|
      if route_set.is_redirect
        route_set.registerable_redirects = [build(:registerable_redirect, :path => route_set.base_path)]
      else
        route_set.registerable_routes = [build(:registerable_route, :path => route_set.base_path)]
      end
    end
  end
end
