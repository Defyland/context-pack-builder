# frozen_string_literal: true

module ContextPackBuilder
  class Builder
    def initialize(project_root:, max_file_chars: 4_000)
      @project_root = project_root
      @max_file_chars = max_file_chars
    end

    def build
      budget = FileBudget.new(max_file_chars: @max_file_chars)
      scan = ProjectScan.new(@project_root, file_budget: budget).to_h
      MarkdownRenderer.new.render(scan)
    end
  end
end
