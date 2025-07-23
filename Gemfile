source "https://rubygems.org"

# --------------------------------------------
# 📦 Rails & Core Gems
# --------------------------------------------
gem "rails", "~> 8.0.2"

# Asset pipeline for Rails
gem "propshaft"

# PostgreSQL as the database
gem "pg", "~> 1.1"

# Web server
gem "puma", ">= 5.0"

# ariáveis de ambiente
gem "dotenv-rails"

# --------------------------------------------
# 🚀 Frontend & Hotwire
# --------------------------------------------
gem "jsbundling-rails"   # JavaScript bundling and transpiling
gem "cssbundling-rails"  # CSS processing
gem "turbo-rails"        # Turbo (Hotwire)
gem "stimulus-rails"     # Stimulus (Hotwire)

# Tailwind CSS integration
gem "tailwindcss-ruby", "~> 4.1"
gem "tailwindcss-rails", "~> 4.3"

# --------------------------------------------
# 🛠 Utilities & APIs
# --------------------------------------------
gem "jbuilder"           # JSON API builder
gem "devise", "~> 4.9"   # Authentication
gem "simple_form"        # Form builder
gem "simple_form-tailwind" # SimpleForm with TailwindCSS
gem "sidekiq"


# Background processing & caching
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Faster application boot time
gem "bootsnap", require: false

# Deployment
gem "kamal", require: false

# HTTP asset caching, compression, and acceleration
gem "thruster", require: false

# --------------------------------------------
# 🔧 Development & Testing
# --------------------------------------------
group :development, :test do
  # Debugging tools
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Security analysis
  gem "brakeman", require: false

  # Linter for Rails projects
  gem "rubocop-rails-omakase", require: false

  # General Ruby linter
  gem "rubocop", "~> 1.78"
end

group :development do
  # Console on exception pages
  gem "web-console"

  # Hotwire debugging tools
  gem "hotwire-spark"
end

group :test do
  # System testing
  gem "capybara"
  gem "selenium-webdriver"
end

# Timezone data for Windows and JRuby
gem "tzinfo-data", platforms: %i[windows jruby]

gem "httparty", "~> 0.23.1"
gem "foreman", "~> 0.88.1"

gem "faraday", "~> 2.13"

gem "prawn"
gem "prawn-table"
