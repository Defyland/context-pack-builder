# frozen_string_literal: true

require "test_helper"

class ContextPackBuilderTest < Minitest::Test
  def test_builds_markdown_pack_with_readiness_signals_and_file_excerpts
    Dir.mktmpdir do |dir|
      write_project(dir)

      markdown = ContextPackBuilder::Builder.new(project_root: dir, max_file_chars: 80).build

      assert_includes markdown, "# Context Pack: #{File.basename(dir)}"
      assert_includes markdown, "- Manifests: `Gemfile`, `Rakefile`, `railway.json`, `openapi.yaml`"
      assert_includes markdown, "`docs/adr/0001-keep-cli-small.md`"
      assert_includes markdown, "- CI: `.github/workflows/ci.yml`"
      assert_includes markdown, "- Contract files: `test/context_pack_builder_test.rb`"
      assert_includes markdown, "- Sensitive file warnings: `.env present`, `Rails master key present`"
      assert_includes markdown, "bundle exec rake test"
      assert_includes markdown, "### `docs/adr/0001-keep-cli-small.md`"
      assert_includes markdown, "### `test/context_pack_builder_test.rb`"
      assert_includes markdown, "### `README.md` (truncated"
      assert_includes markdown, "~~~~md\n# Example"
      refute_includes markdown, "SECRET=do-not-copy"
    end
  end

  def test_limits_contract_file_selection_to_four_high_signal_files
    Dir.mktmpdir do |dir|
      write_project(dir)
      FileUtils.mkdir_p(File.join(dir, "spec"))
      FileUtils.mkdir_p(File.join(dir, "tests"))
      FileUtils.mkdir_p(File.join(dir, "test/nested"))
      File.write(File.join(dir, "test/another_test.rb"), "assert true\n")
      File.write(File.join(dir, "spec/example_spec.rb"), "describe 'example'\n")
      File.write(File.join(dir, "tests/sample_test.go"), "package tests\n")
      File.write(File.join(dir, "test/nested/omitted_test.rb"), "assert true\n")

      markdown = ContextPackBuilder::Builder.new(project_root: dir).build

      assert_equal 4, markdown.scan(/^### `(?:test|spec|tests)\//).count
      refute_includes markdown, "### `test/nested/omitted_test.rb`"
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
    FileUtils.mkdir_p(File.join(dir, "docs/adr"))
    FileUtils.mkdir_p(File.join(dir, "docs"))
    FileUtils.mkdir_p(File.join(dir, "test"))

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
    File.write(File.join(dir, "docs/adr/0001-keep-cli-small.md"), "# ADR\n")
    File.write(File.join(dir, "test/context_pack_builder_test.rb"), "assert true\n")
    File.write(File.join(dir, ".env"), "SECRET=do-not-copy\n")
    File.write(File.join(dir, "config/master.key"), "do-not-copy\n")
  end
end
