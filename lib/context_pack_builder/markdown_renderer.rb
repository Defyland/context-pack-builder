# frozen_string_literal: true

require "json"

module ContextPackBuilder
  class MarkdownRenderer
    def render(scan)
      lines = []
      lines << metadata_comment(scan)
      lines << "# Context Pack: #{scan[:name]}"
      lines << ""
      lines << "Root: `#{scan[:root]}`"
      lines << ""
      lines << "## Readiness Signals"
      lines << ""
      lines << bullet("Manifests", scan[:manifests])
      lines << bullet("Docs", scan[:docs])
      lines << bullet("CI", scan[:ci])
      lines << bullet("Contract files", scan[:contract_files])
      lines << bullet("Sensitive file warnings", scan[:sensitive_file_warnings])
      lines << ""
      lines << "## Git Snapshot"
      lines << ""
      lines.concat(git_lines(scan[:git]))
      lines << ""
      lines << "## Command Snippets"
      lines << ""
      lines.concat(command_lines(scan[:command_snippets]))
      lines << ""
      lines << "## Files"
      lines << ""
      scan[:files].each do |file|
        lines.concat(file_lines(file))
      end
      lines.join("\n")
    end

    private

    def metadata_comment(scan)
      metadata = {
        project: scan[:name],
        generated_at: scan[:generated_at],
        git_commit: scan.dig(:git, :latest_commit_sha),
        git_branch: scan.dig(:git, :branch)
      }
      "<!-- context-pack-builder-meta #{JSON.generate(metadata)} -->"
    end

    def bullet(label, values)
      value = values.empty? ? "_none detected_" : values.map { |item| "`#{item}`" }.join(", ")
      "- #{label}: #{value}"
    end

    def git_lines(git)
      return ["- Git repository: no"] unless git[:available]

      lines = []
      lines << "- Git repository: yes"
      lines << "- Branch: `#{git[:branch].empty? ? "unknown" : git[:branch]}`"
      lines << "- Dirty status: #{git[:status].empty? ? "clean" : git[:status].map { |s| "`#{s}`" }.join(", ")}"
      lines << "- Recent commits:"
      if git[:recent_commits].empty?
        lines << "  - _none_"
      else
        git[:recent_commits].each { |commit| lines << "  - `#{commit}`" }
      end
      lines
    end

    def command_lines(snippets)
      return ["_No shell snippets found in README._"] if snippets.empty?

      snippets.flat_map.with_index(1) do |snippet, index|
        ["### Snippet #{index}", "", "```sh", snippet, "```", ""]
      end
    end

    def file_lines(file)
      language = File.extname(file[:path]).delete_prefix(".")
      language = "text" if language.empty?
      header = "### `#{file[:path]}`"
      header += " (truncated from #{file[:original_chars]} chars)" if file[:truncated]

      [header, "", "~~~~#{language}", file[:body].rstrip, "~~~~", ""]
    end
  end
end
