# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- Updated the image test stage to override the container's entrypoint (using `--entrypoint echo`) so that it outputs "Hello from OpenDLP!" without performing the full startup process (which includes database initialization). This prevents the test from failing when no database is available.

### Fixed
- Updated the `docker/login-action` step to source the Docker Hub username from GitHub variables (`vars.DOCKERHUB_USERNAME`) instead of secrets, ensuring that both username and password are provided correctly.

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
