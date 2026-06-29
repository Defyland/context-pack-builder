# frozen_string_literal: true

require "find"

module ContextPackBuilder
  class ProjectScan
    MANIFESTS = %w[
      Gemfile
      Rakefile
      package.json
      go.mod
      Cargo.toml
      mix.exs
      Dockerfile
      railway.json
      openapi.yaml
      openapi.yml
    ].freeze

    IMPORTANT_DOCS = [
      "README.md",
      "docs/decisions.md",
      "docs/architecture.md",
      "docs/engineering-case-study.md",
      "docs/learning-journal.md"
    ].freeze

    ADR_GLOBS = [
      "docs/adr/*.md",
      "docs/adr/*.markdown"
    ].freeze

    CI_GLOBS = [
      ".github/workflows/*.yml",
      ".github/workflows/*.yaml"
    ].freeze

    CONTRACT_GLOBS = [
      "test/**/*_test.rb",
      "test/**/*_spec.rb",
      "spec/**/*_spec.rb",
      "tests/**/*_test.rb",
      "test/**/*_test.go",
      "tests/**/*_test.go",
      "internal/**/*_test.go",
      "pkg/**/*_test.go",
      "cmd/**/*_test.go",
      "test/**/*_test.exs",
      "tests/**/*_test.exs",
      "tests/**/*.rs"
    ].freeze

    MAX_CONTRACT_FILES = 4

    attr_reader :project_root

    def initialize(project_root, file_budget:)
      @project_root = File.expand_path(project_root)
      @file_budget = file_budget
    end

    def to_h
      {
        name: File.basename(@project_root),
        root: @project_root,
        manifests: existing(MANIFESTS),
        docs: doc_files,
        ci: ci_files,
        contract_files: contract_files,
        sensitive_file_warnings: sensitive_file_warnings,
        command_snippets: command_snippets,
        files: selected_files,
        git: GitSnapshot.new(@project_root).to_h
      }
    end

    private

    def existing(paths)
      paths.select { |path| File.file?(File.join(@project_root, path)) }
    end

    def ci_files
      CI_GLOBS.flat_map { |pattern| Dir.glob(File.join(@project_root, pattern)) }
        .map { |path| relative(path) }
        .sort
    end

    def doc_files
      (existing(IMPORTANT_DOCS) + globbed_files(ADR_GLOBS)).uniq.sort
    end

    def contract_files
      globbed_files(CONTRACT_GLOBS)
        .sort_by { |path| [path.count(File::SEPARATOR), path.length, path] }
        .first(MAX_CONTRACT_FILES)
    end

    def sensitive_file_warnings
      warnings = []
      warnings << ".env present" if File.exist?(File.join(@project_root, ".env"))
      warnings << "Rails master key present" if File.exist?(File.join(@project_root, "config/master.key"))
      warnings << "Kamal secrets file present" if File.exist?(File.join(@project_root, ".kamal/secrets"))
      warnings
    end

    def command_snippets
      readme = File.join(@project_root, "README.md")
      return [] unless File.file?(readme)

      content = File.read(readme, mode: "r:BOM|UTF-8")
      content.scan(/^```(?:sh|bash|shell)\n(.*?)^```/m).flatten.map(&:strip).reject(&:empty?).first(12)
    end

    def selected_files
      candidate_paths.map do |path|
        absolute = File.join(@project_root, path)
        read = @file_budget.read(absolute)
        {
          path: path,
          body: read[:body],
          truncated: read[:truncated],
          original_chars: read[:original_chars]
        }
      end
    end

    def candidate_paths
      paths = []
      paths.concat(doc_files)
      paths.concat(existing(MANIFESTS))
      paths.concat(ci_files)
      paths.concat(contract_files)
      paths.uniq.reject { |path| @file_budget.excluded?(path) }
    end

    def globbed_files(patterns)
      patterns.flat_map { |pattern| Dir.glob(File.join(@project_root, pattern)) }
        .select { |path| File.file?(path) }
        .map { |path| relative(path) }
        .reject { |path| @file_budget.excluded?(path) }
        .sort
    end

    def relative(path)
      path.delete_prefix("#{@project_root}#{File::SEPARATOR}")
    end
  end
end
