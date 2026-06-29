# frozen_string_literal: true

require "fileutils"
require "optparse"

module ContextPackBuilder
  class CLI
    CONTEXT_PACKS_DIR = File.join(".agents", "context-packs").freeze

    def initialize(argv, stdout:, stderr:)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
    end

    def call
      options = parse_options
      project_root = options.fetch(:project_root)
      output = options[:output]
      markdown = Builder.new(project_root: project_root, max_file_chars: options[:max_file_chars]).build

      if output
        FileUtils.mkdir_p(File.dirname(output))
        File.write(output, markdown)
        @stdout.puts "Wrote #{output}"
      else
        @stdout.puts markdown
      end

      0
    rescue OptionParser::ParseError, KeyError => error
      @stderr.puts "error: #{error.message}"
      @stderr.puts parser
      64
    end

    private

    def parse_options
      parser.parse!(@argv)
      options_from_parser[:project_root] ||= @argv.shift
      options_from_parser[:max_file_chars] ||= 4_000
      raise KeyError, "project path is required" unless options_from_parser[:project_root]
      if options_from_parser[:output] && options_from_parser[:workspace_output]
        raise KeyError, "--output and --workspace-output cannot be used together"
      end

      if options_from_parser[:workspace_output]
        options_from_parser[:output] = workspace_output_path(options_from_parser[:project_root])
      end

      options_from_parser
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: context-pack-builder [options] PROJECT_PATH"
        opts.on("-o", "--output PATH", "Write markdown context pack to PATH") do |value|
          (@options ||= {})[:output] = value
        end
        opts.on("--max-file-chars N", Integer, "Maximum characters copied per file") do |value|
          (@options ||= {})[:max_file_chars] = value
        end
        opts.on("--workspace-output", "Write to the nearest .agents/context-packs/<project>.md") do
          (@options ||= {})[:workspace_output] = true
        end
      end
    end

    def options_from_parser
      @options ||= {}
    end

    def workspace_output_path(project_root)
      project_root = File.expand_path(project_root)
      current = project_root

      loop do
        context_packs_dir = File.join(current, CONTEXT_PACKS_DIR)
        if File.directory?(context_packs_dir)
          return File.join(context_packs_dir, "#{File.basename(project_root)}.md")
        end

        parent = File.dirname(current)
        break if parent == current

        current = parent
      end

      raise KeyError, "no workspace context-pack directory found above #{project_root}"
    end
  end
end
