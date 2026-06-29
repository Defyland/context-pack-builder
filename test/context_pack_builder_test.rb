# frozen_string_literal: true

require "test_helper"

class ContextPackBuilderTest < Minitest::Test
  def test_builds_markdown_pack_with_readiness_signals_and_file_excerpts
    Dir.mktmpdir do |dir|
      write_project(dir)

      markdown = ContextPackBuilder::Builder.new(project_root: dir, max_file_chars: 80).build

      assert_includes markdown, "# Context Pack: #{File.basename(dir)}"
      assert_includes markdown, "- Manifests: `Gemfile`, `Rakefile`, `railway.json`, `openapi.yaml`"
      assert_includes markdown, "- Docs: `README.md`, `docs/decisions.md`, `docs/architecture.md`"
      assert_includes markdown, "- CI: `.github/workflows/ci.yml`"
      assert_includes markdown, "- Sensitive file warnings: `.env present`, `Rails master key present`"
      assert_includes markdown, "bundle exec rake test"
      assert_includes markdown, "### `README.md` (truncated"
      assert_includes markdown, "~~~~md\n# Example"
      refute_includes markdown, "SECRET=do-not-copy"
    end
  end

  def test_cli_writes_output_file
    Dir.mktmpdir do |dir|
      write_project(dir)
      output = File.join(dir, "tmp", "context.md")
      stdout = StringIO.new
      stderr = StringIO.new

      status = ContextPackBuilder::CLI.new([dir, "--output", output], stdout: stdout, stderr: stderr).call

      assert_equal 0, status
      assert File.file?(output)
      assert_includes File.read(output), "# Context Pack:"
      assert_includes stdout.string, "Wrote #{output}"
      assert_empty stderr.string
    end
  end

  def test_cli_requires_project_path
    stdout = StringIO.new
    stderr = StringIO.new

    status = ContextPackBuilder::CLI.new([], stdout: stdout, stderr: stderr).call

    assert_equal 64, status
    assert_includes stderr.string, "project path is required"
    assert_empty stdout.string
  end

  private

  def write_project(dir)
    FileUtils.mkdir_p(File.join(dir, ".github/workflows"))
    FileUtils.mkdir_p(File.join(dir, "config"))
    FileUtils.mkdir_p(File.join(dir, "docs"))

    File.write(File.join(dir, "README.md"), <<~README)
      # Example

      ```sh
      bundle exec rake test
      bin/rails db:prepare
      ```

      #{'long text ' * 30}
    README
    File.write(File.join(dir, "Gemfile"), "source 'https://rubygems.org'\n")
    File.write(File.join(dir, "Rakefile"), "task default: :test\n")
    File.write(File.join(dir, "openapi.yaml"), "openapi: 3.1.0\n")
    File.write(File.join(dir, "railway.json"), "{}\n")
    File.write(File.join(dir, ".github/workflows/ci.yml"), "name: CI\n")
    File.write(File.join(dir, "docs/decisions.md"), "# Decisions\n")
    File.write(File.join(dir, "docs/architecture.md"), "# Architecture\n")
    File.write(File.join(dir, ".env"), "SECRET=do-not-copy\n")
    File.write(File.join(dir, "config/master.key"), "do-not-copy\n")
  end
end
