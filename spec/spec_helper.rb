require 'sprockets'
require 'sprockets-sassc'
require 'sprockets-helpers'
require 'compass'
require 'test_construct'

Compass.configuration do |compass|
  compass.line_comments = false
  compass.output_style  = :nested
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
    # Only run specs with the 'focus' tag
    # See infor here:
    # http://stackoverflow.com/questions/6116668/rspec-how-to-run-a-single-test
    # https://www.relishapp.com/rspec/rspec-core/v/2-6/docs/filtering/inclusion-filters
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true

    config.include TestConstruct::Helpers
end
