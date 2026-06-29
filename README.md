# Context Pack Builder

`context-pack-builder` creates compact Markdown context packs for backend projects. The goal is to make a repository easier for a small or cheap model to operate without pasting an entire codebase into the prompt.

It scans the teaching and operating surfaces that matter most:

- README and key docs
- architecture, decisions, case study, and learning journal files
- manifests such as `Gemfile`, `go.mod`, `Cargo.toml`, `mix.exs`, `Dockerfile`, `railway.json`, and OpenAPI files
- GitHub Actions workflows
- command snippets from README fenced shell blocks
- git branch, dirty status, and recent commits
- warnings for sensitive files such as `.env`, `config/master.key`, and `.kamal/secrets`

## Why This Exists

AI-assisted engineering gets expensive when every task starts with a messy context dump. The useful alternative is a small, repeatable artifact that tells a model what the project is, how to run it, which docs are canonical, what is risky, and which files prove the current contract.

This project is the first asset in the `backend-challenges` AI-ready technical asset program. It is intentionally local-first and dependency-light so it can run inside any repository before a larger gateway or eval system exists.

## Install

Inside this repository:

```sh
bundle install
```

## Usage

Print a context pack:

```sh
bin/context-pack-builder ../rails_doctor
```

Write a context pack to a file:

```sh
bin/context-pack-builder ../rails_doctor --output tmp/rails_doctor.context.md
```

Limit copied content per selected file:

```sh
bin/context-pack-builder ../rails_doctor --max-file-chars 2000
```

## Output Contract

The Markdown output contains:

1. readiness signals for manifests, docs, CI, and sensitive file warnings;
2. git snapshot with current branch, dirty status, and recent commits;
3. README command snippets;
4. selected file excerpts with truncation markers.

The output is not a secret scanner and not a full static analyzer. It is a context primitive for later tooling.

## Development

Run tests:

```sh
bundle exec rake test
```

Run the CLI against this project:

```sh
bin/context-pack-builder .
```

## Design Boundaries

- Markdown is the first output format because it is directly pasteable into model context.
- The scanner reads a curated set of high-signal files instead of recursively summarizing everything.
- Sensitive files are warned about, not copied.
- The implementation uses Ruby standard library plus Minitest/Rake for a small maintenance surface.

## Next Steps

- Add JSON output for programmatic eval tooling.
- Add token-budget estimation.
- Add per-stack presets for Rails, Go, Rust, and Elixir projects.
- Feed generated packs into an `eval-harness`.
