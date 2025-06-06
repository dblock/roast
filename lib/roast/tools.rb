# frozen_string_literal: true

require "active_support/cache"
require "English"
require "fileutils"

require "roast/tools/grep"
require "roast/tools/read_file"
require "roast/tools/search_file"
require "roast/tools/write_file"
require "roast/tools/update_files"
require "roast/tools/cmd"
require "roast/tools/coding_agent"
require "roast/tools/ask_user"

module Roast
  module Tools
    extend self

    # Initialize cache and ensure .gitignore exists
    cache_dir = File.join(Dir.pwd, ".roast", "cache")
    FileUtils.mkdir_p(cache_dir) unless File.directory?(cache_dir)

    # Add .gitignore to cache directory
    gitignore_path = File.join(cache_dir, ".gitignore")
    File.write(gitignore_path, "*") unless File.exist?(gitignore_path)

    CACHE = ActiveSupport::Cache::FileStore.new(cache_dir)

    def file_to_prompt(file)
      <<~PROMPT
        # #{file}

        #{File.read(file)}
      PROMPT
    rescue StandardError => e
      Roast::Helpers::Logger.error("In current directory: #{Dir.pwd}\n")
      Roast::Helpers::Logger.error("Error reading file #{file}\n")

      raise e # unable to continue without required file
    end

    def setup_interrupt_handler(object_to_inspect)
      Signal.trap("INT") do
        puts "\n\nCaught CTRL-C! Printing before exiting:\n"
        puts JSON.pretty_generate(object_to_inspect)
        exit(1)
      end
    end

    def setup_exit_handler(context)
      # Hook that runs on any exit (including crashes and unhandled exceptions)
      at_exit do
        if $ERROR_INFO && !$ERROR_INFO.is_a?(SystemExit) # If exiting due to unhandled exception
          puts "\n\nExiting due to error: #{$ERROR_INFO.class}: #{$ERROR_INFO.message}\n"
          # Temporary disable the debugger to fix directory issues
          # context.instance_eval { binding.irb }
        end
      end
    end
  end
end
