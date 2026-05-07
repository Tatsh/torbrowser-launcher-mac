<!-- markdownlint-configure-file {"MD024": { "siblings_only": true } } -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-05-07

### Added

- Tests and Coverage status badges to the README.

### Changed

- Updated development dependencies, including cspell, markdownlint-cli2, prettier, and
  prettier-plugin-sort-json.
- Updated GitHub Actions dependencies, including actions/checkout, actions/configure-pages,
  actions/deploy-pages, actions/upload-artifact, actions/attest-build-provenance, and
  github/codeql-action.
- Refreshed project scaffolding via cruft, including the QA workflow (now uses a virtual
  environment for linting tools) and the CMake workflow (uploads attested build artefacts with
  unique names).

## [0.1.0]

General maintenance release.

## [0.0.1] - 2025-00-00

First version.

[unreleased]: https://github.com/Tatsh/torbrowser-launcher-mac/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/Tatsh/torbrowser-launcher-mac/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Tatsh/torbrowser-launcher-mac/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/Tatsh/torbrowser-launcher-mac/releases/tag/v0.0.1
