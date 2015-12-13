require 'spec_helper'

describe Sprockets::Sassc::SassTemplate do

  before :each do
    # Pass the custom importer class
    @custom_importer =  Sprockets::Sassc::DummyImporter
    Sprockets::Sassc.options[:importer] = @custom_importer

    # Initialize the environment.
    @root = create_construct
    @assets = @root.directory 'assets'
    @env = Sprockets::Environment.new @root.to_s
    @env.append_path @assets.to_s
    @env.register_postprocessor 'text/css', :fail_postprocessor do |_, data|
      data.gsub /@import/, 'fail engine'
    end
  end

  after :each do
    @root.destroy!
  end

  it 'allow specifying custom sass importer' do
    @assets.file 'main.css.scss', %(@import "dep";)
    @assets.file 'dep.css.scss', "$color: blue;\nbody { color: $color; }"
    @env['main.css']

    expect(@custom_importer.has_been_used).to be_truthy
  end

end
