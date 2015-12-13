require 'tilt'
require 'pathname'

module Sprockets
	module Sassc
		class Importer < ::SassC::Importer
			class Extension
				attr_reader :postfix

				def initialize(postfix=nil)
					@postfix = postfix
				end

				def import_for(full_path, parent_dir, options)
					eval_content = evaluate(options[:sprockets][:context], full_path)
					SassC::Importer::Import.new(full_path, source: eval_content)
				end
				
				# Returns the string to be passed to the Sass engine. We use
				# Sprockets to process the file, but we remove any Sass processors
				# because we need to let the Sass::Engine handle that.
				def evaluate(context, path)
					attributes = context.environment.attributes_for(path)
					processors = context.environment.preprocessors(attributes.content_type) + attributes.engines.reverse
					processors.delete_if { |processor| processor < Tilt::SassTemplate }
					
					result = context.evaluate(path, :processors => processors)
					
					# sassc doesn't support sass syntax, convert sass to scss
					# before returning result.
					if Pathname.new(path).basename.to_s.include?('.sass')
						result = SassC::Sass2Scss.convert(result)
					end
					
				end
			end
			
			class CSSExtension < Extension
				def postfix
					".css"
				end
				
				# def import_for(full_path, parent_dir, options)
				# 	import_path = full_path.gsub(/\.css$/,"")
				# 	SassC::Importer::Import.new(import_path)
				# end
			end
			
			class CssScssExtension < Extension
				def postfix
					".css.scss"
				end
			end
			
			class CssSassExtension < Extension
				def postfix
					".css.sass"
				end
				
				def import_for(full_path, parent_dir, options)
					sass = evaluate(options[:sprockets][:context], full_path)
					parsed_scss = SassC::Sass2Scss.convert(sass)
					SassC::Importer::Import.new(full_path, source: parsed_scss)
				end
			end
			
			class SassERBExtension < Extension
				def postfix
					".sass.erb"
				end
			end
			
			class ERBExtension < Extension
				
			end

			EXTENSIONS = [
				CssScssExtension.new,
				CssSassExtension.new,
				Extension.new(".scss"),
				Extension.new(".sass"),
				CSSExtension.new,
				ERBExtension.new(".scss.erb"),
				ERBExtension.new(".css.erb"),
				SassERBExtension.new
			]

			PREFIXS = [ "", "_" ]
			GLOB = /(\A|\/)(\*|\*\*\/\*)\z/

			def imports(path, parent_path)
				
				puts "importer: \npath='#{path}'\nparent_path='#{parent_path}'\n"
				
				# Resolve a glob
				if m = path.match(GLOB)
					path = path.sub(m[0], "")
					base = File.expand_path(path, File.dirname(parent_path))
					return glob_imports(base, m[2], parent_path)
				end
				
				# Resolve a single file
				return import_file_original(path, parent_path)
			end
			
			
			# Resolve single file (split out from original `#imports` method)
			def import_file_original(path, parent_path)
				parent_dir, _ = File.split(parent_path)
				
				ctx = options[:sprockets][:context]
				paths = collect_paths(ctx, path, parent_dir)
				
				found_path = resolve_to_path(ctx, paths)
				record_import_as_dependency found_path
				return Extension.new().import_for(found_path.to_s, parent_dir, options)

				# SassC::Importer::Import.new(path)
			end
			
			
			def collect_paths(context, path, parent_path)
				# In regular sass `parent_path` is absolute,
				# in sassc it may be relative, so make sure it is absolute.
				parent_path = Pathname.new(parent_path)
				if parent_path.relative?
					# Append the Sprockets root_path.
					parent_path = Pathname.new(context.root_path).join(parent_path)
				end
				
				parent_dir = parent_path.dirname
				specified_dir, specified_file = File.split(path)
				specified_dir = Pathname.new(specified_dir)
				
				search_paths = [specified_dir.to_s]
				
				# Find parent_dir's root
				if specified_dir.relative?
					
					env_root_paths = env_paths.map {|p| Pathname.new(p) }
					root_path = env_root_paths.detect do |env_root_path|
						# Return the root path that contains `parent_dir`
						parent_dir.to_s.start_with?(env_root_path.to_s)
					end
					root_path ||= Pathname.new(context.root_path)
					
					if parent_dir != root_path
						# Get any remaining path relative to root
						relative_path = Pathname.new(parent_path).relative_path_from(root_path)
						search_paths.unshift(relative_path.join(specified_dir).to_s)
					end
					
				end
				
				
				paths = search_paths.map { |search_path|
					PREFIXS.map { |prefix|
						file_name = prefix + specified_file
						File.join(search_path, file_name)
					}
				}.flatten
								
				
				# parent_path = Pathname.new(parent_path)
				# paths = [parent_path]
				# 
				# # Find base_path's root
				# env_root_paths = env_paths.map { |p| Pathname.new(p) }
				# root_path = env_root_paths.detect do |env_root_path|
				# 	parent_path.to_s.start_with?(env_root_path.to_s)
				# end
				# 
				# # Work out the relative path first.
				# if parent_path.relative? && parent_path != root_path
				# 	relative_path = parent_path.relative_path_from(root_path)
				# 	paths.unshift(relative_path)
				# end
				# 
				# paths.compact
			end
			
			
			# Finds an asset from the given path. This is where
			# we make Sprockets behave like Sass, and import partial
			# style paths.
			def resolve_to_path(context, paths)
				paths.each { |file|
					context.resolve(file) { |try_path|
						# Early exit if we find a requirable file.
						return try_path if context.asset_requirable?(try_path)
					}
				}
				
				nil
			end
			

			# def imports(path, parent_path)
			# 	parent_dir, _ = File.split(parent_path)
			# 	specified_dir, specified_file = File.split(path)
			#
			# 	if m = path.match(GLOB)
			# 		path = path.sub(m[0], "")
			# 		base = File.expand_path(path, File.dirname(parent_path))
			# 		return glob_imports(base, m[2], parent_path)
			# 	end
			#
			# 	search_paths = ([parent_dir] + load_paths).uniq
			#
			# 	if specified_dir != "."
			# 		search_paths.map! do |path|
			# 			File.join(path, specified_dir)
			# 		end
			# 	end
			#
			# 	search_paths.each do |search_path|
			# 		PREFIXS.each do |prefix|
			# 			file_name = prefix + specified_file
			#
			# 			EXTENSIONS.each do |extension|
			# 				try_path = File.join(search_path, file_name + extension.postfix)
			# 				if File.exists?(try_path)
			# 					record_import_as_dependency try_path
			# 					return extension.import_for(try_path, parent_dir, options)
			# 				end
			# 			end
			# 		end
			# 	end
			#
			# 	SassC::Importer::Import.new(path)
			# end

			private

			def extension_for_file(file)
				EXTENSIONS.detect do |extension|
					file.include? extension.postfix
				end
			end

			def record_import_as_dependency(path)
				context.depend_on path
			end

			def context
				options[:sprockets][:context]
			end

			def load_paths
				options[:load_paths]
			end
			
			# Machined/Sprockets paths...
			def env_paths
				context.environment.paths
			end

			# # Resolve a single file in the Sprockets environment
			# def import_file(path, parent_path)
			# 	# Behaviour:
			# 	# 
			# 	# 
			# 	# 
			# end

			# def glob_imports(base, glob, current_file)
			# 	files = globbed_files(base, glob)
			# 	files = files.reject { |f| f == current_file }
			#
			# 	files.map do |filename|
			# 		record_import_as_dependency(filename)
			# 		extension = extension_for_file(filename)
			# 		extension.import_for(filename, base, options)
			# 	end
			# end
			#
			# def globbed_files(base, glob)
			# 	# TODO: Raise an error from SassC here
			# 	raise ArgumentError unless glob == "*" || glob == "**/*"
			#
			# 	extensions = EXTENSIONS.map(&:postfix)
			# 	exts = extensions.map { |ext| Regexp.escape("#{ext}") }.join("|")
			# 	sass_re = Regexp.compile("(#{exts})$")
			#
			# 	record_import_as_dependency(base)
			#
			# 	files = Dir["#{base}/#{glob}"].sort.map do |path|
			# 		if File.directory?(path)
			# 			record_import_as_dependency(path)
			# 			nil
			# 		elsif sass_re =~ path
			# 			path
			# 		end
			# 	end
			#
			# 	files.compact
			# end

		end
	end
end
