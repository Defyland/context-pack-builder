# frozen_string_literal: true

require "fileutils"
require "optparse"

module ContextPackBuilder
  class CLI
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
      end
    end

    def options_from_parser
      @options ||= {}
    end
  end
end
