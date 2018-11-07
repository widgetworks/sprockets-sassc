require 'sprockets'
require 'sprockets/sassc/version'
require 'sprockets/sassc/sass_template'
require 'sprockets/sassc/scss_template'
require 'sprockets/engines'
require 'sassc'

# DEBUG ONLY
require 'colorize'

module Sprockets
  module Sassc
    autoload :CacheStore, 'sprockets/sassc/cache_store'
    autoload :Importer,   'sprockets/sassc/importer'

    class << self
      # Global configuration for `Sass::Engine` instances.
      attr_accessor :options

      # When false, the asset path helpers provided by
      # sprockets-helpers will not be added as Sass functions.
      # `true` by default.
      attr_accessor :add_sass_functions
    end

    ##
    # 2018-11-07
    # Add `trim_import_chars` 
    ##
    @options = {
      line_comments: true,
      trim_import_chars: /^~#/
    }
    @add_sass_functions = true
    
    puts "! Using sprockets-sassc".red
    
  end

  register_engine '.sass', Sassc::SassTemplate
  register_engine '.scss', Sassc::ScssTemplate
end
