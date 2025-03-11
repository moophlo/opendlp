# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- Added the missing closing `fi` in the GitHub Actions `Set up Docker tags` step to fix a syntax error (unexpected end of file).

### Fixed
- Corrected syntax error in GitHub Actions `Set up Docker tags` step by properly quoting `GITHUB_REF` and specifying `shell: bash` to prevent YAML parsing issues.

### Added
- Initial GitHub Actions CI/CD workflow
- Multi-architecture build
- Version tagging (SHA + v1.0.0 tags)
- Metadata image labels
- Healthcheck
- Docker test stage
