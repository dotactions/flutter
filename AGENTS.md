# Agents Rules for dotactions/flutter

Opinionated composite actions and reusable workflows for building and shipping Flutter apps, consumed by other repositories. Every change here ships to every consumer, so correctness and pinning discipline outrank convenience.

## CRITICAL INSTRUCTIONS

1. **The Ponytail Workflow (Default Execution Mode)**:
    - Climb the senior dev ladder: YAGNI -> Reuse -> Stdlib -> Platform -> Deps -> Simplicity -> Minimal Diff.
    - Deletion over addition. Boring over clever.
    - Mark intentional simplifications with `ponytail:` comments (`# ponytail:` in YAML/shell/PowerShell, `// ponytail:` in TypeScript) naming the known ceiling and upgrade path.
    - Non-trivial logic must leave behind at least one runnable check (see [Testing](#testing)).

2. **Commit Policy**:
    - AI assistants are strictly prohibited from generating, suggesting, or running git commits, pushes, tags, or releases under any circumstance. Commits and releases are human-only.

3. **Plan Execution Policy**:
    - **Never** proceed to code changes or implementation commands directly from a plan unless the human developer explicitly replies with direct authorization (e.g., "go ahead", "approved", "execute").
    - A plan is strictly for review. Keep your hands off the files until permission is explicitly given.

4. **Comments & Standards**:
    - Strictly NO inline comments explaining syntax or obvious actions. Comments explain _why_ (constraints, GitHub quirks, security reasons), never _what_.
    - Ceiling of 300 lines per file (excluding `README.md`, lockfiles, fixtures and `dist/`). Always ask before performing major file splits or autonomous refactoring.

## Repository Layout

| Path | Purpose |
| :--- | :--- |
| `setup/`, `build/`, `matrix/` | Public composite actions (`action.yml` + `scripts/`) |
| `build/targets.json` | Single source of truth for valid Flutter targets and their runner OS |
| `.github/workflows/ci.yml`, `cd.yml` | Public reusable workflows (`workflow_call`) |
| `.github/workflows/internal-test.yml` | Tests the actions via `uses: ./<action>` against `tests/fixtures/` |
| `.github/workflows/internal-*.yml` | Thin callers of `dotactions/tooling` (see [Shared CI](#shared-ci-dotactionstooling)) |
| `.tooling/` | `dotactions/tooling` submodule: `tests/lib.sh` harness only |
| `tests/*.test.sh`, `tests/fixtures/` | Script unit tests; minimal Flutter project |

## Pinning & References

- Every third-party `uses:` is pinned to a full commit SHA with a version comment: `uses: owner/repo@<40-char-sha> # vX.Y.Z`. Resolve SHAs with `git ls-remote --tags`; never guess or invent one. If you cannot resolve it, stop and ask.
- Another `dotactions` repo is pinned the same way, to the commit of its **release tag** (`git ls-remote https://github.com/dotactions/<repo> 'refs/tags/vX.Y.Z^{}'`), never to a `main` SHA: only release commits have their own `@main` self-references rewritten. `internal-check-refs.yml` fails on anything else.
- References to this repo's own actions **must** be `dotactions/flutter/<path>@main` with the comment `# @main is rewritten to the exact release tag by internal-release.yml`. Never write a tag or SHA for a self-reference.
- Composite actions cannot reference sibling actions by relative path. Inside a reusable workflow, `./` points at the **caller's** repo. Never "fix" this with a checkout of `dotactions/flutter` at a branch.

## Shared CI (`dotactions/tooling`)

- `internal-release.yml`, `internal-check-refs.yml`, `internal-actionlint.yml`, `internal-lint.yml`, `internal-test-scripts.yml` are thin callers of `dotactions/tooling/.github/workflows/*.yml`. They only hold `on:`/`paths:`, `permissions:` and `with:`. Logic changes go to `tooling`, not here.
- Callers never declare `concurrency:`; the called workflow does, and an identical group in caller and callee deadlocks.

## Inputs, Scripts & Security

- Never interpolate `${{ }}` directly into `run:`. Pass values through `env:` and reference `"$VAR"`.
- Logic longer than a few lines goes into `<action>/scripts/*.sh` (bash, `set -euo pipefail`) or `*.ps1`, not inline YAML. Scripts must pass ShellCheck / PSScriptAnalyzer.
- Validate inputs early and fail with `::error::` messages naming the allowed values.
- Workflows declare `permissions: contents: read` at the top level and widen per job only where required.
- Input defaults must not duplicate data that lives elsewhere (Flutter version from the consumer's `pubspec.yaml`, targets from `targets.json`).

## Public API & Versioning

- Inputs, outputs, input defaults, artifact names and reusable-workflow `with:`/`secrets:` are public API. Renaming, removing or changing the default of any of them is a **breaking change**: flag it explicitly in your response so the human can bump the major version.
- Every public input/output change must be reflected in `README.md` (tables + usage examples).
- Releases are cut only by the human via the `Release` workflow (`internal-release.yml`). Never create or move tags.

## Testing

- Composite actions are tested via `uses: ./<action>` in `internal-test.yml`, with assertions on outputs and produced files. Add or extend a test for every behavioural change.
- Script logic is unit-tested in `tests/<name>.test.sh` using the harness from the `.tooling` submodule (`source "$(dirname "$0")/../.tooling/tests/lib.sh"`; run `git submodule update --init` first). `internal-test-scripts.yml` runs every one on ubuntu, macOS and Windows. Add cases for every branch you change.
- Each `internal-*` workflow has a `paths:` filter. When adding files that a workflow should cover, update its filter.
- Local checks before finishing (run whichever apply):
    - `shellcheck <changed .sh files>`
    - `bash tests/*.test.sh`
    - Exercise changed scripts directly with sample env vars and a temp `GITHUB_OUTPUT` / `GITHUB_ENV`
    - `docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12` for workflow changes
- Report honestly which checks ran and which could not (e.g. multi-OS builds only run in CI).
