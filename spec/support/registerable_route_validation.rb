RSpec.shared_examples_for "a valid registerable route" do
  it 'validates type is either "exact" or "prefix"' do
    %w(exact prefix).each do |type|
      route = build(factory_name, :type => type)
      expect(route).to be_valid
    end

    %w(invalid types).each do |type|
      route = build(factory_name, :type => type)
      expect(route).to_not be_valid
      expect(route.errors[:type].size).to eq(1)
    end
  end

  it 'validates path is absolute' do
    route = build(factory_name, :path => 'not-absolute-path')

    expect(route).to_not be_valid
    expect(route.errors[:path].size).to eq(1)
  end
end
