module Sprockets
  module Sassc

    class DummyImporter < Importer
      @@has_been_used = false

      def self.has_been_used
          @@has_been_used
      end

      def initialize(options = {})
        super(options)
        @@has_been_used = false
      end

      def imports(path, parent_path)
          @@has_been_used = true
          super(path, parent_path)
      end

    end

  end
end
