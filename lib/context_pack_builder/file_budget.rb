# frozen_string_literal: true

module ContextPackBuilder
  class FileBudget
    DEFAULT_EXCLUDED_DIRS = %w[
      .bundle
      .git
      coverage
      dist
      log
      node_modules
      pkg
      tmp
      vendor
    ].freeze

    DEFAULT_EXCLUDED_FILES = [
      ".env",
      ".env.local",
      "config/master.key"
    ].freeze

    def initialize(max_file_chars:, excluded_dirs: DEFAULT_EXCLUDED_DIRS, excluded_files: DEFAULT_EXCLUDED_FILES)
      @max_file_chars = max_file_chars
      @excluded_dirs = excluded_dirs
      @excluded_files = excluded_files
    end

    def excluded?(path)
      parts = path.split(File::SEPARATOR)
      return true if (parts & @excluded_dirs).any?

      @excluded_files.include?(path)
    end

    def read(path)
      content = File.read(path, mode: "r:BOM|UTF-8")
      truncated = content.length > @max_file_chars
      body = truncated ? content[0, @max_file_chars] : content

      {body: body, truncated: truncated, original_chars: content.length}
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
      {body: "[binary or unsupported encoding omitted]", truncated: true, original_chars: File.size(path)}
    end
  end
end
