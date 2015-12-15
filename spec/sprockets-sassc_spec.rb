require 'spec_helper'

describe Sprockets::Sassc do
  before :each do
    @root = create_construct
    @assets = @root.directory 'assets'
    @env = Sprockets::Environment.new @root.to_s
    @env.append_path @assets.to_s
    @env.register_postprocessor 'text/css', :fail_postprocessor do |context, data|
      data.gsub /@import/, 'fail engine'
    end
  end

  after :each do
    @root.destroy!
  end

  it 'processes scss files normally', :focus => false do
    @assets.file 'main.css.scss', '//= require dep'
    @assets.file 'dep.css.scss', 'body { color: blue; }'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'processes sass files normally', :focus => false do
    @assets.file 'main.css.sass', '//= require dep'
    @assets.file 'dep.css.sass', "body\n  color: blue"
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports standard files', :focus => false do
    @assets.file 'main.css.scss', %(@import "dep";\nbody { color: $color; })
    @assets.file 'dep.css.scss', '$color: blue;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports partials', :focus => false do
    @assets.file 'main.css.scss', %(@import "_dep";\nbody { color: $color; })
    @assets.file '_dep.css.scss', '$color: blue;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports other syntax', :focus => false do
    @assets.file 'main.css.scss', %(@import "dep";\nbody { color: $color; })
    @assets.file 'dep.sass', "$color: blue\nhtml\n  height: 100%"
    asset = @env['main.css']
    expect(asset.to_s).to eql("html {\n  height: 100%; }\n\nbody {\n  color: blue; }\n")
  end

  it 'imports files with the correct content type', :focus => false do
    @assets.file 'main.css.scss', %(@import "dep";\nbody { color: $color; })
    @assets.file 'dep.js', 'var app = {};'
    @assets.file '_dep.css.scss', '$color: blue;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports files with directives', :focus => false do
    @assets.file 'main.css.scss', %(@import "dep";)
    @assets.file 'dep.css', "/*\n *= require subdep\n */"
    @assets.file 'subdep.css.scss', "$color: blue;\nbody { color: $color; }"
    asset = @env['main.css']
    expect(asset.to_s).to include("body {\n  color: blue; }\n")
  end

  it 'imports files with additional processors', :focus => false do
    @assets.file 'main.css.scss', %(@import "dep";\nbody { color: $color; })
    @assets.file 'dep.css.scss.erb', "$color: <%= 'blue' %>;"
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports relative files', :focus => false do
    @assets.file 'folder/main.css.scss', %(@import "./dep-1";\n@import "./subfolder/dep-2";\nbody { background-color: $background-color; color: $color; })
    @assets.file 'folder/dep-1.css.scss', '$background-color: red;'
    @assets.file 'folder/subfolder/dep-2.css.scss', '$color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  background-color: red;\n  color: blue; }\n")
  end

  it 'imports relative partials', :focus => false do
    @assets.file 'folder/main.css.scss', %(@import "./dep-1";\n@import "./subfolder/dep-2";\nbody { background-color: $background-color; color: $color; })
    @assets.file 'folder/_dep-1.css.scss', '$background-color: red;'
    @assets.file 'folder/subfolder/_dep-2.css.scss', '$color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  background-color: red;\n  color: blue; }\n")
  end

  it 'imports deeply nested relative partials', :focus => false do
    @assets.file 'package-prime/stylesheets/main.scss', %(@import "package-dep/src/stylesheets/variables";\nbody { background-color: $background-color; color: $color; })
    @assets.file 'package-dep/src/stylesheets/_variables.scss', %(@import "./colors";\n$background-color: red;)
    @assets.file 'package-dep/src/stylesheets/_colors.scss', '$color: blue;'
    asset = @env['package-prime/stylesheets/main.scss']
    expect(asset.to_s).to eql("body {\n  background-color: red;\n  color: blue; }\n")
  end

  it 'imports relative files without preceding ./', :focus => false do
    @assets.file 'folder/main.css.scss', %(@import "dep-1";\n@import "subfolder/dep-2";\nbody { background-color: $background-color; color: $color; })
    @assets.file 'folder/dep-1.css.scss', '$background-color: red;'
    @assets.file 'folder/subfolder/dep-2.css.scss', '$color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  background-color: red;\n  color: blue; }\n")
  end

  it 'imports relative partials without preceding ./', :focus => false do
    @assets.file 'folder/main.css.scss', %(@import "dep-1";\n@import "subfolder/dep-2";\nbody { background-color: $background-color; color: $color; })
    @assets.file 'folder/_dep-1.css.scss', '$background-color: red;'
    @assets.file 'folder/subfolder/_dep-2.css.scss', '$color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  background-color: red;\n  color: blue; }\n")
  end

  it 'imports files relative to root', :focus => false do
    @assets.file 'folder/main.css.scss', %(@import "dep";\nbody { color: $color; })
    @assets.file 'dep.css.scss', '$color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports partials relative to root', :focus => false do
    @assets.file 'folder/main.css.scss', %(@import "dep";\nbody { color: $color; })
    @assets.file '_dep.css.scss', '$color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'shares Sass environment with other imports', :focus => false do
    @assets.file 'main.css.scss', %(@import "dep-1";\n@import "dep-2";)
    @assets.file '_dep-1.scss', '$color: blue;'
    @assets.file '_dep-2.scss', 'body { color: $color; }'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports files from the assets load path', :focus => false do
    vendor = @root.directory 'vendor'
    @env.append_path vendor.to_s

    @assets.file 'main.css.scss', %(@import "dep";\nbody { color: $color; })
    vendor.file 'dep.css.scss', '$color: blue;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports nested partials with relative path from the assets load path', :focus => false do
      # TODO: Inspect the environment load path for this test case - curious to know what values we'll have.
    vendor = @root.directory 'vendor'
    @env.append_path vendor.to_s

    @assets.file 'folder/main.css.scss', %(@import "dep";\nbody { color: $color; })
    vendor.file 'dep.css.scss', '@import "folder1/dep1";'
    vendor.file 'folder1/_dep1.scss', '@import "folder2/dep2";'
    vendor.file 'folder1/folder2/_dep2.scss', '$color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports nested partials with relative path and glob from the assets load path', :focus => false do
    vendor = @root.directory 'vendor'
    @env.append_path vendor.to_s

    @assets.file 'folder/main.css.scss', %(@import "dep";\nbody { color: $color; })
    vendor.file 'dep.css.scss', '@import "folder1/dep1";'
    vendor.file 'folder1/_dep1.scss', '@import "folder2/*";'
    vendor.file 'folder1/folder2/_dep2.scss', '$color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
  end

  it 'imports nested partials with relative paths from the Sass load path (requires SassC absolute parent_path)', :focus => false do
    # This test requires the absolute parent_path to be passed from sassc
    # https://github.com/sass/sassc-ruby/pull/28
    @assets.file 'main.css.scss', %(@import "user1/_all-vars";\nbody { color: $color; })
    @assets.file 'user1/_all-vars.scss', '@import "vars/*";'
    @assets.file 'user1/vars/_user-vars.scss', '$color: blue;'
    @assets.file 'user2/vars/_user-vars.scss', '$color: red;'
  
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
    Sprockets::Sassc.options.delete(:load_paths)
  end


  it 'same import from different parent returns different content', :focus => false do
    # I think there is an issue in libsass/sassc that causes it to return
    # the same information for the same glob regardless of whether different
    # results are returned (e.g. for different parent directories).
    @assets.file 'main.css.scss', %(@import "user1/_all-vars";\n@import "user2/_all-vars";\n.user1 { color: $color1; }\n.user2 { color: $color2; })
    @assets.file 'user1/_all-vars.scss', '@import "vars/user-vars";'
    @assets.file 'user1/vars/_user-vars.scss', '$color1: blue;'
  
    @assets.file 'user2/_all-vars.scss', '@import "vars/user-vars";'
    @assets.file 'user2/vars/_user-vars.scss', '$color2: red;'
  
    asset = @env['main.css']
    expect(asset.to_s).to eql(".user1 {\n  color: blue; }\n\n.user2 {\n  color: red; }\n")
    Sprockets::Sassc.options.delete(:load_paths)
  end
  
  it 'same glob from different parent returns different content', :focus => false do
    # I think there is an issue in libsass/sassc that causes it to return
    # the same information for the same glob regardless of whether different
    # results are returned (e.g. for different parent directories).
    @assets.file 'main.css.scss', %(@import "user1/_all-vars";\n@import "user2/_all-vars";\n.user1 { color: $color1; };\n.user2 { color: $color2; })
    @assets.file 'user1/_all-vars.scss', '@import "vars/*";'
    @assets.file 'user1/vars/_user-vars.scss', '$color1: blue;'
    
    @assets.file 'user2/_all-vars.scss', '@import "vars/*";'
    @assets.file 'user2/vars/_user-vars.scss', '$color2: red;'
  
    asset = @env['main.css']
    expect(asset.to_s).to eql(".user1 {\n  color: blue; }\n\n.user2 {\n  color: red; }\n")
    Sprockets::Sassc.options.delete(:load_paths)
  end
  
  it 'allows global Sass configuration', :focus => false do
    Sprockets::Sassc.options[:style] = :compact
    @assets.file 'main.css.scss', "body {\n  color: blue;\n}"

    asset = @env['main.css']
    expect(asset.to_s).to eql("body { color: blue; }\n")
    Sprockets::Sassc.options.delete(:style)
  end

  it 'imports files from the Sass load path', :focus => false do
    vendor = @root.directory 'vendor'
    Sprockets::Sassc.options[:load_paths] = [ vendor.to_s ]

    @assets.file 'main.css.scss', %(@import "dep";\nbody { color: $color; })
    vendor.file 'dep.scss', '$color: blue;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue; }\n")
    Sprockets::Sassc.options.delete(:load_paths)
  end

  # it 'works with the Compass framework' do
  #   @assets.file 'main.css.scss', %(@import "compass/css3";\nbutton { @include border-radius(5px); })
  # 
  #   asset = @env['main.css']
  #   expect(asset.to_s).to include('border-radius: 5px;')
  # end

  it 'imports globbed files', :focus => false do
    @assets.file 'main.css.scss', %(@import "folder/*";\nbody { color: $color; background: $bg-color; })
    @assets.file 'folder/dep-1.css.scss', '$color: blue;'
    @assets.file 'folder/dep-2.css.scss', '$bg-color: red;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue;\n  background: red; }\n")
  end

  it 'processes globbed scss.erb files', :focus => false do
    @assets.file 'main.css.scss', %(@import "folder/*";\nbody { color: $color; background: $bg-color; })
    @assets.file 'folder/dep-1.css.scss.erb', "$color: <%= 'blue' %>;"
    @assets.file 'folder/dep-2.css.scss', '$bg-color: red;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue;\n  background: red; }\n")
  end

  it 'adds dependencies when imported', :focus => false do
    @assets.file 'main.css.scss', %(@import "dep";\nbody { color: $color; })
    dep = @assets.file 'dep.css.scss', '$color: blue;'

    asset = @env['main.css']
    expect(asset).to be_fresh(@env)

    mtime = Time.now + 1
    dep.open('w') { |f| f.write '$color: red;' }
    dep.utime mtime, mtime

    expect(asset).to_not be_fresh(@env)
  end

  it 'adds dependencies from assets when imported', :focus => false do
    @assets.file 'main.css.scss', %(@import "dep-1";\nbody { color: $color; })
    @assets.file 'dep-1.css.scss', %(@import "dep-2";\n)
    dep = @assets.file 'dep-2.css.scss', '$color: blue;'

    asset = @env['main.css']
    expect(asset).to be_fresh(@env)

    mtime = Time.now + 1
    dep.open('w') { |f| f.write '$color: red;' }
    dep.utime mtime, mtime

    expect(asset).to_not be_fresh(@env)
  end

  it 'adds dependencies when imported from a glob', :focus => false do
    @assets.file 'main.css.scss', %(@import "folder/*";\nbody { color: $color; background: $bg-color; })
    @assets.file 'folder/_dep-1.scss', '$color: blue;'
    dep = @assets.file 'folder/_dep-2.scss', '$bg-color: red;'

    asset = @env['main.css']
    expect(asset).to be_fresh(@env)

    mtime = Time.now + 1
    dep.open('w') { |f| f.write "$bg-color: white;" }
    dep.utime mtime, mtime

    expect(asset).to_not be_fresh(@env)
  end

  it "uses the environment's cache", :focus => false do
    cache = {}
    @env.cache = cache

    @assets.file 'main.css.scss', %($color: blue;\nbody { color: $color; })

    @env['main.css'].to_s
    if Sass.version[:minor] > 2
      sass_cache = cache.detect.detect { |key, value| value['pathname'] =~ /main\.css\.scss/ }
    else
      sass_cache = cache.keys.detect { |key| key =~ /main\.css\.scss/ }
    end
    expect(sass_cache).to_not be_nil
  end
  
  # # sassc-ruby doesn't support maps yet so these tests have been disabled.
  # it 'adds the #asset_path helper', :focus => true do
  #   # FIXME
  #   @assets.file 'asset_path.css.scss', %(body { background: url(asset-path("image.jpg")); })
  #   @assets.file 'asset_url.css.scss', %(body { background: asset-url("image.jpg"); })
  #   @assets.file 'asset_path_options.css.scss', %(body { background: url(asset-path("image.jpg", {$digest: true, $prefix: "/themes"})); })
  #   @assets.file 'asset_url_options.css.scss', %(body { background: asset-url("image.jpg", $digest: true, $prefix: "/themes"); })
  #   @assets.file 'image.jpg'
  # 
  #   expect(@env['asset_path.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg"); }\n))
  #   expect(@env['asset_url.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg"); }\n))
  #   expect(@env['asset_path_options.css'].to_s).to match(%r(body \{\n  background: url\("/themes/image-[0-9a-f]+.jpg"\); \}\n))
  #   expect(@env['asset_url_options.css'].to_s).to match(%r(body \{\n  background: url\("/themes/image-[0-9a-f]+.jpg"\); \}\n))
  # end
  # 
  # it 'adds the #image_path helper', :focus => false do
  #   # FIXME
  #   @assets.file 'image_path.css.scss', %(body { background: url(image-path("image.jpg")); })
  #   @assets.file 'image_url.css.scss', %(body { background: image-url("image.jpg"); })
  #   @assets.file 'image_path_options.css.scss', %(body { background: url(image-path("image.jpg", $digest: true, $prefix: "/themes")); })
  #   @assets.file 'image_url_options.css.scss', %(body { background: image-url("image.jpg", $digest: true, $prefix: "/themes"); })
  #   @assets.file 'image.jpg'
  # 
  #   expect(@env['image_path.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg"); }\n))
  #   expect(@env['image_url.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg"); }\n))
  #   expect(@env['image_path_options.css'].to_s).to match(%r(body \{\n  background: url\("/themes/image-[0-9a-f]+.jpg"\); \}\n))
  #   expect(@env['image_url_options.css'].to_s).to match(%r(body \{\n  background: url\("/themes/image-[0-9a-f]+.jpg"\); \}\n))
  # end
  # 
  # it 'adds the #font_path helper', :focus => false do
  #   # FIXME
  #   @assets.file 'font_path.css.scss', %(@font-face { src: url(font-path("font.ttf")); })
  #   @assets.file 'font_url.css.scss', %(@font-face { src: font-url("font.ttf"); })
  #   @assets.file 'font_path_options.css.scss', %(@font-face { src: url(font-path("font.ttf", $digest: true, $prefix: "/themes")); })
  #   @assets.file 'font_url_options.css.scss', %(@font-face { src: font-url("font.ttf", $digest: true, $prefix: "/themes"); })
  #   @assets.file 'font.ttf'
  # 
  #   expect(@env['font_path.css'].to_s).to eql(%(@font-face {\n  src: url("/assets/font.ttf"); }\n))
  #   expect(@env['font_url.css'].to_s).to eql(%(@font-face {\n  src: url("/assets/font.ttf"); }\n))
  #   expect(@env['font_path_options.css'].to_s).to match(%r(@font-face \{\n  src: url\("/themes/font-[0-9a-f]+.ttf"\); \}\n))
  #   expect(@env['font_url_options.css'].to_s).to match(%r(@font-face \{\n  src: url\("/themes/font-[0-9a-f]+.ttf"\); \}\n))
  # end

  it 'adds the #asset_data_uri helper', :focus => false do
    # FIXME
    @assets.file 'asset_data_uri.css.scss', %(body { background: asset-data-uri("image.jpg"); })
    @assets.file 'image.jpg', File.read('spec/fixtures/image.jpg')

    expect(@env['asset_data_uri.css'].to_s).to include("body {\n  background: url(data:image/jpeg;base64,")
  end
  
  # # sassc doesn't support booleans yet
  # it "mirrors Compass's #image_url helper", :focus => true do
  #   # FIXME
  #   @assets.file 'image_path.css.scss', %(body { background: url(image-url("image.jpg", true)); })
  #   @assets.file 'image_url.css.scss', %(body { background: image-url("image.jpg", false); })
  #   @assets.file 'cache_buster.css.scss', %(body { background: image-url("image.jpg", false, true); })
  #   @assets.file 'image.jpg'
  # 
  #   expect(@env['image_path.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg"); }\n))
  #   expect(@env['image_url.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg"); }\n))
  #   expect(@env['cache_buster.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg"); }\n))
  # end
  # 
  # it "mirrors Compass's #font_url helper", :focus => false do
  #   # FIXME
  #   @assets.file 'font_path.css.scss', %(@font-face { src: url(font-url("font.ttf", true)); })
  #   @assets.file 'font_url.css.scss', %(@font-face { src: font-url("font.ttf", false); })
  #   @assets.file 'font.ttf'
  # 
  #   expect(@env['font_path.css'].to_s).to eql(%(@font-face {\n  src: url("/assets/font.ttf"); }\n))
  #   expect(@env['font_url.css'].to_s).to eql(%(@font-face {\n  src: url("/assets/font.ttf"); }\n))
  # end
  # 
  # it "mirrors Sass::Rails's #asset_path helpers", :focus => true do
  #   @assets.file 'asset_path.css.scss', %(body { background: url(asset-path("image.jpg", image)); })
  #   @assets.file 'asset_url.css.scss', %(body { background: asset-url("icon.jpg", image); })
  #   @assets.file 'image.jpg'
  # 
  #   expect(@env['asset_path.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg"); }\n))
  #   expect(@env['asset_url.css'].to_s).to eql(%(body {\n  background: url("/images/icon.jpg"); }\n))
  # end

  # it 'allows asset helpers from within Compass mixins', :focus => true do
  #   @assets.file 'bullets.css.scss', %(@import "compass";\nul { @include pretty-bullets('bullet.gif', 10px, 10px); })
  #   @assets.file 'bullet.gif'
  # 
  #   expect(@env['bullets.css'].to_s).to match(%r[background: url\("/assets/bullet\.gif"\)])
  # end
  
  # it 'compresses css', :focus => false do
  #   css = "div {\n  color: red;\n}\n"
  #   compressed_css = Sprockets::Sassc::Compressor.new.compress(css)
  #   expect(compressed_css).to eql("div{color:red}\n")
  # end

  describe Sprockets::Sassc::SassTemplate do
    describe 'initialize_engine' do
      it 'initializes super if super is uninitinalized' do
        Tilt::SassTemplate.stub(:engine_initialized?).and_return false
        template = Sprockets::Sassc::SassTemplate.new {}
        template.should_receive(:require_template_library) # called from Tilt::SassTemplate.initialize
        template.initialize_engine
      end

      it 'does not initializes super if super is initinalized to silence warnings' do
        Tilt::SassTemplate.stub(:engine_initialized?).and_return true
        template = Sprockets::Sassc::SassTemplate.new {}
        template.should_not_receive(:require_template_library) # called from Tilt::SassTemplate.initialize
        template.initialize_engine
      end

      it 'does not add Sass functions if sprockets-helpers is not available' do
          # FIXME
        template = Sprockets::Sassc::SassTemplate.new {}
        template.should_not_receive(:require).with('sprockets/helpers').and_raise LoadError
        template.should_receive(:require).with 'sprockets/sassc/functions'
        template.initialize_engine
        expect(Sprockets::Sassc::SassTemplate.engine_initialized?).to be_truthy
      end

      it 'does not add Sass functions if add_sass_functions is false' do
        Sprockets::Sassc.add_sass_functions = false
        template = Sprockets::Sassc::SassTemplate.new {}
        template.should_not_receive(:require).with 'sprockets/sassc/functions'
        template.initialize_engine
        expect(Sprockets::Sassc::SassTemplate.engine_initialized?).to be_truthy
        Sprockets::Sassc.add_sass_functions = true
      end

      it 'adds Sass functions if add_sass_functions is not false' do
        Sprockets::Sassc.add_sass_functions = true
        template = Sprockets::Sassc::SassTemplate.new {}
        template.should_receive(:require).with 'sprockets/sassc/functions'
        template.initialize_engine
        expect(Sprockets::Sassc::SassTemplate.engine_initialized?).to be_truthy
        Sprockets::Sassc.add_sass_functions = true
      end
    end
  end
end
