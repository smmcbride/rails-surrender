# frozen_string_literal: true

appraise 'rails-7.0' do
  gem 'rails', '~> 7.0.0'
  # ActiveSupport before 8.1 passes quirks_mode to JSON.generate, which json 3 no longer accepts.
  gem 'json', '< 3'
  # Rails 7.0 needs the older test gems: rspec-rails 8 and sqlite3 2 require Rails 7.1 or newer.
  gem 'rspec-rails', '~> 7.0'
  gem 'sqlite3', '~> 1.4'
  # Rails 7.0 reads Logger before requiring it, which concurrent-ruby 1.3.5 stopped loading for it.
  gem 'concurrent-ruby', '< 1.3.5'
end

appraise 'rails-7.1' do
  gem 'rails', '~> 7.1.0'
  # ActiveSupport before 8.1 passes quirks_mode to JSON.generate, which json 3 no longer accepts.
  gem 'json', '< 3'
  # rspec-rails 8 requires Rails 7.2, and Rails 7.1's SQLite adapter requires sqlite3 1.x.
  gem 'rspec-rails', '~> 7.0'
  gem 'sqlite3', '~> 1.4'
end

appraise 'rails-7.2' do
  gem 'rails', '~> 7.2.0'
  # ActiveSupport before 8.1 passes quirks_mode to JSON.generate, which json 3 no longer accepts.
  gem 'json', '< 3'
end

appraise 'rails-8.0' do
  gem 'rails', '~> 8.0.0'
  # ActiveSupport 8.0 passes quirks_mode to JSON.generate, which json 3 no longer accepts.
  gem 'json', '< 3'
end

appraise 'rails-8.1' do
  gem 'rails', '~> 8.1.0'
end
