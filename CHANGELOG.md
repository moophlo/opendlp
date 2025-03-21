# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- Updated the "Set up Docker tags" step in the GitHub Actions workflow to check if the FROM line in the Dockerfile contains a colon. If no tag is specified, it defaults the base_tag to "latest". This prevents an invalid image tag format (e.g., "moophlo/opendlp:FROM ubuntu/apache2") and resolves the build error.

### Fixed
- Modified the test stage in the GitHub Actions workflow to use `docker buildx build --load`, ensuring that the built test image is loaded into the local Docker engine. This resolves the issue where the test image wasn't found due to the build result remaining in the build cache.

### Added
- Extracted the base image tag from the Dockerfile’s FROM line and added it as an additional image tag during the push. This allows tracking of the underlying base image version used in the build.

### Added
- Updated the GitHub Actions workflow to derive the Docker image name dynamically from the GitHub repository name (using `${{ github.repository }}`), ensuring the image is tagged as `githubuser/repositoryname`.
- Modified the trigger so that the workflow runs only when the `Dockerfile` changes (using the `paths` filter) and on version tag pushes.
- Maintained existing tags for latest, commit SHA, semantic version (if applicable), and the base image tag from the Dockerfile.

### Added
- Modified the GitHub Actions workflow to convert the derived image name from `${{ github.repository }}` to all lowercase (using `tr`), ensuring that the Docker image name is always in lowercase.

### Added
- non-interactive CA generation script replicating demoCA structure
  - Introduce a shell script to generate the CA key and self-signed certificate non-interactively.
  - Replicate the traditional demoCA directory schema (private, newcerts, index.txt, and serial file) as expected by /etc/ssl/openssl.cnf and existing commands.
  - Generate the CA private key (with optional passphrase removal) and CA certificate (valid for 10 years) to ensure compatibility with start.sh.
  - This change enables automated CA setup in Docker environments without requiring interactive input.

### Fixed
- Updated the `generate_certificates` function to generate a CSR for the server certificate and sign it with the CA instead of self-signing it. This ensures that the certificate verification in `check_certificates` passes on subsequent startups, preventing the reboot loop. Fixed compose.yml errors.

### Added
- Updated `docker-compose.yml` to define database credentials (username and password) using YAML anchors. Both MySQL and OpenDLP now source the credentials from the same values, ensuring consistency and avoiding potential mismatches.

### Added
- Created a `docker-compose.yml` file that defines two services:
  - **MySQL 5.7**: Configured with persistent storage (`mysql_data`), a healthcheck, and environment variables for the database, user, and password.
  - **OpenDLP**: Configured to wait until MySQL is healthy (using `depends_on` with `condition: service_healthy`), with matching environment variables for `OPENDLP_DB_USER` and `OPENDLP_DB_PASS`, and persistent volumes (`opendlp_ssl` and `opendlp_www`) for its configuration and data.


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
