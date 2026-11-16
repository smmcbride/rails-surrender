# frozen_string_literal: true

RSpec.describe Rails::Surrender::MenuRoute do
  def drawn(route)
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw { route.draw(self) }
    routes.routes.map { |drawn_route| [drawn_route.path.spec.to_s, drawn_route.defaults] }
  end

  it 'is off by default, at /surrender_menu' do
    expect(described_class.new).to have_attributes(enabled: false, path: '/surrender_menu')
  end

  it 'draws the menu at its path when on' do
    expect(drawn(described_class.new(enabled: true, path: '/docs')))
      .to eq([['/docs(.:format)', { controller: 'rails/surrender/menus', action: 'show' }]])
  end

  it 'draws nothing while off, leaving the path to the app' do
    expect(drawn(described_class.new(enabled: false))).to be_empty
  end

  it 'takes no route name, so it never clashes with the app' do
    routes = ActionDispatch::Routing::RouteSet.new
    route = described_class.new(enabled: true)
    routes.draw { route.draw(self) }

    expect(routes.named_routes.names).to be_empty
  end

  it 'refuses a path that does not start with /' do
    expect { described_class.new(path: 'docs') }.to raise_error(ArgumentError, %r{start with /})
  end
end
