# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.3.5'

gem 'postmark-rails'

gem 'activeadmin'
gem 'devise'
gem 'figaro'
gem 'jbuilder', '~> 2.0'
gem 'pg', '~> 0.21'
gem 'puma', '~> 3.10.0'
gem 'rails', '5.1.4'
gem 'redis'

# FRONT
# Font Awesome gem
gem 'font-awesome-rails'
# To create micro-components for the frontend
gem 'vuejs-rails', '~> 2.3.2'
# To have more interactive select dropdown menus
gem "select2-rails"
# Needed to use bootstrap tooltips
source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
  gem 'rails-assets-popper.js', '>= 1.14.1'
  gem 'rails-assets-js-cookie'
end
gem 'bootstrap-sass'
gem 'font-awesome-sass'
gem 'formtastic'
gem 'sass-rails'
gem 'simple_form'

gem 'autoprefixer-rails'
gem 'paper_trail'
gem 'pundit'
gem 'rack-attack'
gem 'uglifier'

gem 'recaptcha'

# for tosback2:
gem 'capybara'
gem 'poltergeist'
gem 'sanitize'

group :development do
  gem 'letter_opener'
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'active_record_query_trace'
  gem 'bullet'
  gem 'flamegraph'
  gem 'listen', '~> 3.0.5'
  gem 'memory_profiler'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rack-mini-profiler'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'stackprof'
end

group :production do
  gem 'heroku-deflater'
end
