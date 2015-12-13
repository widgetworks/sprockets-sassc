require 'tilt'

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
					context.evaluate(path, :processors => processors)
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
				specified_dir, specified_file = File.split(path)
				
				search_paths = ([parent_dir] + load_paths).uniq

				if specified_dir != "."
					search_paths.map! do |path|
						File.join(path, specified_dir)
					end
				end

				search_paths.each do |search_path|
					PREFIXS.each do |prefix|
						file_name = prefix + specified_file

						EXTENSIONS.each do |extension|
							try_path = File.join(search_path, file_name + extension.postfix)
							if File.exists?(try_path)
								record_import_as_dependency try_path
								return extension.import_for(try_path, parent_dir, options)
							end
						end
					end
				end

				SassC::Importer::Import.new(path)
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
