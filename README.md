# dotactions/flutter

Composite actions and reusable workflows to set up, test, build and package Flutter apps for Linux, macOS, Windows, Android and iOS.

## Versioning

This repo is on **0.x** until release artifacts can be signed (see [Limitations](#limitations)). During `0.x`, a **minor** release may contain breaking changes.

Pin the **full commit SHA** of a release tag, with the version in a comment, or a floating minor tag:

```yaml
uses: dotactions/flutter/.github/workflows/ci.yml@<40-char-sha> # v0.1.0
uses: dotactions/flutter/.github/workflows/ci.yml@v0.1
```

Resolve a SHA with `git ls-remote https://github.com/dotactions/flutter 'refs/tags/v0.1.0^{}'`. Only SHAs of **release tags** pin the whole tree; a SHA from `main` still contains `@main` self-references.

| Ref | Moves on | Use |
| :-- | :-- | :-- |
| `@<sha>` | never | **Recommended**: immutable, full reproducibility |
| `@v0.1` | patch releases of `0.1` | **Recommended**: bug fixes, no breaking changes |
| `@v0.1.0` | never (tag can be moved) | Readable, but tags are mutable |
| `@v0` | every `0.x` release | Not recommended: during `0.x`, minor releases may break you |

Release notes: [GitHub Releases](https://github.com/dotactions/flutter/releases).

## Limitations

- **Artifacts are unsigned.** iOS builds use `--no-codesign` and can't be installed. macOS apps are neither signed nor notarized, so Gatekeeper blocks them. Android release builds use your project's own signing config, which in the Flutter template is the debug key, so the Play Store rejects them. Windows executables aren't signed. v1.0.0 follows once signing is supported.
- **Desktop builds are x64 only** (`ubuntu-latest`, `windows-latest`); arm64 runners aren't supported yet.

## Permissions

Examples assume a **public** repository. In a **private** repository, `actions/checkout` needs `contents: read`, so every job using these actions (or `ci.yml`) must grant it:

```yaml
permissions:
    contents: read # required for private repos; optional for public
```

Reusable workflows can only narrow the caller's token permissions, never widen them. Grant the permissions listed under each workflow in the calling job.

## Actions

### Build Flutter (`build`)

Sets up Flutter, automatically resolves app metadata from `pubspec.yaml`, installs target dependencies, builds binaries in release, debug, or profile mode, and packages artifacts for Linux, macOS, Windows, Android (android-apk/android-aab), or iOS.

> **Prerequisite**: Run `actions/checkout` before calling this action.

> **Flutter version**: unless `flutter-version` is passed, the SDK version is read from `environment.flutter` in `<working-directory>/pubspec.yaml`. An exact version is recommended; a range (`^3.47.1`, `">=3.47.1 <4.0.0"`) installs its lower bound:
>
> ```yaml
> environment:
>     sdk: ^3.13.1
>     flutter: 3.47.1
> ```

#### Inputs

| Name                | Description                                                                          | Required | Default     |
| :------------------ | :----------------------------------------------------------------------------------- | :------- | :---------- |
| `target`            | Target platform: `linux`, `macos`, `windows`, `android-apk`, `android-aab`, or `ios` | Yes      | -           |
| `flutter-version`   | Flutter SDK version (empty reads `environment.flutter` from `pubspec.yaml`)          | No       | `""`        |
| `channel`           | Flutter release channel                                                              | No       | `"stable"`  |
| `cache`             | Cache Flutter SDK artifacts                                                          | No       | `"true"`    |
| `working-directory` | Directory containing `pubspec.yaml`                                                  | No       | `"."`       |
| `build-mode`        | Build compilation mode: `debug`, `profile`, or `release`                             | No       | `"release"` |

#### Outputs

| Name            | Description                                   |
| :-------------- | :-------------------------------------------- |
| `artifact-name` | Base name for the generated artifact          |
| `artifact-path` | Glob of the packaged archive(s), in a directory under the runner temp folder that the action owns |

#### Usage

```yaml
- name: Build Flutter App
  uses: dotactions/flutter/build@v0.1
  with:
      target: "linux"
```

### Setup Flutter (`setup`)

Installs the Flutter SDK and runs `flutter pub get`.

> **Prerequisite**: Run `actions/checkout` before calling this action.

> **Flutter version**: unless `flutter-version` is passed, the SDK version is read from `environment.flutter` in `<working-directory>/pubspec.yaml`. An exact version is recommended; a range (`^3.47.1`, `">=3.47.1 <4.0.0"`) installs its lower bound:
>
> ```yaml
> environment:
>     sdk: ^3.13.1
>     flutter: 3.47.1
> ```

#### Inputs

| Name                | Description                                                                 | Required | Default    |
| :------------------ | :-------------------------------------------------------------------------- | :------- | :--------- |
| `flutter-version`   | Flutter SDK version (empty reads `environment.flutter` from `pubspec.yaml`) | No       | `""`       |
| `channel`           | Flutter release channel                                                     | No       | `"stable"` |
| `cache`             | Cache Flutter SDK artifacts                                                 | No       | `"true"`   |
| `working-directory` | Directory containing `pubspec.yaml`                                         | No       | `"."`      |

#### Usage

```yaml
- uses: dotactions/flutter/setup@v0.1
- run: flutter analyze
```

### Flutter Matrix (`matrix`)

Validates Flutter targets and resolves a `strategy.matrix` (target + runner OS) and build mode for the current event. Used internally by `ci.yml` and `cd.yml`. The list of valid targets and their runners is defined in [`build/targets.json`](build/targets.json).

#### Inputs

| Name              | Description                                                    | Required | Default |
| :---------------- | :------------------------------------------------------------- | :------- | :------ |
| `targets`         | JSON array of targets for all events (overrides the two below) | No*      | `""`    |
| `pr-targets`      | JSON array of targets on `pull_request`                        | No*      | `""`    |
| `push-targets`    | JSON array of targets on push / other events                   | No*      | `""`    |
| `build-mode`      | Build mode for all events (overrides the two below)            | No       | `""`    |
| `pr-build-mode`   | Build mode on `pull_request` (falls back to `"debug"`)         | No       | `""`    |
| `push-build-mode` | Build mode on push / other events (falls back to `"release"`)  | No       | `""`    |

_Provide either `targets` or both `pr-targets` and `push-targets`. Duplicate targets are rejected._

#### Outputs

| Name         | Description                                                |
| :----------- | :--------------------------------------------------------- |
| `matrix`     | JSON array of `{target, os}` for `strategy.matrix.include` |
| `build-mode` | Resolved build mode                                        |

#### Usage

```yaml
jobs:
    matrix:
        runs-on: ubuntu-latest
        outputs:
            matrix: ${{ steps.m.outputs.matrix }}
        steps:
            - id: m
              uses: dotactions/flutter/matrix@v0.1
              with:
                  targets: '["linux", "windows"]'
    build:
        needs: matrix
        runs-on: ${{ matrix.os }}
        strategy:
            matrix:
                include: ${{ fromJson(needs.matrix.outputs.matrix) }}
        steps:
            - uses: actions/checkout@v7
            - uses: dotactions/flutter/build@v0.1
              with:
                  target: ${{ matrix.target }}
```

## Workflows

### Flutter CI (`ci.yml`)

Runs Flutter static analysis, unit tests, and cross-platform compilation across a specified list of targets. Builds start only after analysis and tests pass.

#### Permissions Required

```yaml
permissions:
    contents: read # required on private repos; harmless on public
```

#### Flutter Version

Unless `flutter-version` is passed, the SDK version is read from `environment.flutter` in `<working-directory>/pubspec.yaml`. An exact version is recommended; a range (`^3.47.1`, `">=3.47.1 <4.0.0"`) installs its lower bound:

```yaml
environment:
    sdk: ^3.13.1
    flutter: 3.47.1
```

#### Inputs

| Name                | Description                                                                 | Required | Default |
| :------------------ | :-------------------------------------------------------------------------- | :------- | :------ |
| `pr-targets`        | JSON array of targets to build on pull request (e.g. `'["linux"]'`)         | No*      | `""`    |
| `push-targets`      | JSON array of targets to build on push (e.g. `'["linux", "macos"]'`)        | No*      | `""`    |
| `targets`           | JSON array of targets to build for all events (overrides above)             | No*      | `""`    |
| `flutter-version`   | Flutter SDK version (empty reads `environment.flutter` from `pubspec.yaml`) | No       | `""`    |
| `working-directory` | Directory containing `pubspec.yaml`                                         | No       | `"."`   |
| `build-mode`        | Universal build mode (`debug`, `profile`, `release`) (overrides below)      | No       | `""`**  |
| `pr-build-mode`     | Build mode on pull request (defaults to `"debug"`)                          | No       | `""`**  |
| `push-build-mode`   | Build mode on push/merge (defaults to `"release"`)                          | No       | `""`**  |
| `concurrency-tests` | Number of concurrent test runners                                           | No       | `4`     |

\* Provide either `targets` or both `pr-targets` and `push-targets`.

\*\* If none are provided, PR build mode is `"debug"` and push build mode is `"release"`.

#### Usage

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
    push:
        branches: [main]
        paths-ignore: ["**.md"]
    pull_request:
        branches: ["**"]
        paths-ignore: ["**.md"]

concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true

jobs:
    ci:
        uses: dotactions/flutter/.github/workflows/ci.yml@v0.1
        with:
            pr-targets: '["android-apk"]'
            push-targets: '["android-aab", "windows"]'
            # or a target for all events:
            # targets: '["linux"]'

            pr-build-mode: "debug"
            push-build-mode: "release"
            # or a build mode for all events:
            # build-mode: 'release'
```

### Flutter CD (`cd.yml`)

Builds release packages across specified platforms and uploads them directly to a GitHub release.

#### Permissions Required

```yaml
permissions:
    contents: write # for uploading release assets
```

#### Flutter Version

Unless `flutter-version` is passed, the SDK version is read from `environment.flutter` in `<working-directory>/pubspec.yaml`. An exact version is recommended; a range (`^3.47.1`, `">=3.47.1 <4.0.0"`) installs its lower bound:

```yaml
environment:
    sdk: ^3.13.1
    flutter: 3.47.1
```

#### Inputs

| Name                | Description                                                                 | Required | Default |
| :------------------ | :-------------------------------------------------------------------------- | :------- | :------ |
| `targets`           | JSON array of targets to build (e.g. `'["linux", "windows"]'`)              | Yes      | -       |
| `tag`               | Target release tag (required unless triggered by a release or tag push)     | No       | `""`    |
| `flutter-version`   | Flutter SDK version (empty reads `environment.flutter` from `pubspec.yaml`) | No       | `""`    |
| `working-directory` | Directory containing `pubspec.yaml`                                         | No       | `"."`   |

#### Secrets

| Name    | Description                                               | Required |
| :------ | :-------------------------------------------------------- | :------- |
| `token` | GitHub token with write access (defaults to GITHUB_TOKEN) | No       |

#### Usage

```yaml
# .github/workflows/release.yml
name: Release

on:
    release:
        types: [published]
    workflow_dispatch:
        inputs:
            tag:
                description: "Release tag"
                required: false

concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: false

jobs:
    cd:
        uses: dotactions/flutter/.github/workflows/cd.yml@v0.1
        permissions:
            contents: write
        with:
            targets: '["linux", "windows", "macos", "android-aab"]'
            tag: ${{ inputs.tag || github.event.release.tag_name }}
```

## Releasing (maintainers)

Merge to `main` with conventional-commit PR titles (they become the release notes), then run the **Release** workflow (`internal-release.yml`) from `main` with a version, e.g. `1.2.0` or `1.2.0-rc.1`. It pins self-references to the release tag, creates the GitHub release and moves the floating tags; see [dotactions/tooling](https://github.com/dotactions/tooling).

Bump the **minor** version for breaking changes and the **patch** version for everything else (`0.x`).
