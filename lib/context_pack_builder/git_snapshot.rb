# frozen_string_literal: true

require "open3"

module ContextPackBuilder
  class GitSnapshot
    def initialize(project_root)
      @project_root = project_root
    end

    def to_h
      return {available: false} unless File.directory?(File.join(@project_root, ".git"))

      {
        available: true,
        branch: capture("git", "branch", "--show-current").strip,
        status: capture("git", "status", "--short").lines.map(&:chomp),
        recent_commits: capture("git", "log", "--oneline", "-n", "8").lines.map(&:chomp)
      }
    end

    private

    def capture(*command)
      stdout, _stderr, status = Open3.capture3(*command, chdir: @project_root)
      status.success? ? stdout : ""
    end
  end
end
