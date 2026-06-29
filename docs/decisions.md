# Technical Decisions

## 2026-06-29 - Start With A Local Markdown Context Pack Builder

Context: The `backend-challenges` workspace is becoming a set of AI-ready technical assets. Cheap models need clean, compact context: project purpose, commands, docs, manifests, git state, and risk signals. The immediate need is a reusable artifact that every project can generate before broader model-routing or eval tooling exists.

Options considered:

- Build a full AI gateway first, with model routing, caching, redaction, and budget accounting.
- Build an eval harness first, with tests and architecture checks across all projects.
- Build a local context pack builder first.

Choice: Build a local Markdown context pack builder first.

Pros:

- Immediately useful across every repository in the workspace.
- Keeps the first asset small enough to verify with tests.
- Produces context that can be consumed by any model or thread.
- Does not require network access, API keys, or a database.
- Creates a stable input for later eval and gateway tools.

Cons:

- Markdown is less convenient for machines than JSON.
- It does not prove that the selected docs are correct.
- It only warns about sensitive file names; it is not a full secret scanner.
- It does not yet estimate token count.

Consequences:

- Future tools should treat this output as an input artifact, not as a security boundary.
- A later JSON mode should reuse the same scan model instead of adding another scanner.
- Per-stack presets can be added after the generic contract proves useful.

Verification evidence:

- `bundle exec rake test`
- `bin/context-pack-builder .`

## 2026-06-29 - Include Curated Contract Evidence In Context Packs

Context: The first version captured project prose, manifests, and CI, but small models still had to guess how behavior was proven. For this workspace, executable tests and ADRs are part of the operating context, especially when the goal is safer AI-assisted changes.

Options considered:

- Keep packs focused on prose and manifests only.
- Summarize arbitrary source trees.
- Include a curated set of ADRs and representative contract tests.

Choice: Include ADR files and a small capped set of high-signal contract tests.

Pros:

- Gives models direct examples of executable behavior without dumping the whole repository.
- Surfaces decision history that often explains why tests and interfaces look the way they do.
- Keeps output bounded enough for cheap-model context windows.
- Works across the Ruby, Go, Rust, and Elixir projects in this workspace with simple heuristics.

Cons:

- File-pattern heuristics will miss some stack-specific test shapes.
- A capped sample can omit lower-priority tests.
- This is still a curated context artifact, not full-code understanding.

Consequences:

- The builder now treats ADRs and contract tests as first-class context surfaces.
- Future stack presets can improve which contract files are selected without changing the Markdown contract.
- `eval-harness` remains the place for readiness gating; the builder only packages evidence.

Verification evidence:

- `bundle exec rake test`
- `bin/context-pack-builder ../rails_doctor`
