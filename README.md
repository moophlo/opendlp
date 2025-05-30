# OpenDLP - Production Ready Docker Image

This project provides a **production-ready Docker image for OpenDLP**, built and automatically published using GitHub Actions.

> **Forked from:** [ezarko/opendlp](https://github.com/ezarko/opendlp)  
We acknowledge and appreciate the work done in the upstream project.

## 🛠 Project Goals

- Create a modern, automated, multi-architecture Docker build for OpenDLP
- Automatically publish new Docker images on every push and version tag via GitHub Actions
- Provide flexible customization options via environment variables
- Include TLS certificate generation and database initialization on container startup

## 📦 Docker Image

Docker Hub: [`moophlo/opendlp`](https://hub.docker.com/r/moophlo/opendlp)

Supported tags:
- `latest`
- `git-sha` (e.g., `moophlo/opendlp:abc1234`)
- Semantic versioning (e.g., `moophlo/opendlp:v1.0.0`)

## ⚙ Environment Variable Configuration

The container supports several environment variables for customization at runtime:

### 🔐 Certificate and CA Customization

| Variable | Description | Default |
|---------|-------------|---------|
| `APACHE_SSL_SUBJ` | Subject string for server certificate | `/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=example.com` |
| `APACHE_CLIENT_SUBJ` | Subject string for client certificate | `/C=US/ST=State/L=City/O=MyOrg/OU=Clients/CN=client1` |
| `APACHE_CERT_PASS` | Passphrase used for certificates | `password` |
| `OPENSSL_CONFIG` | OpenSSL config file path | `/etc/ssl/openssl.cnf` |

### 🗄 Database Configuration

| Variable | Description | Default |
|---------|-------------|---------|
| `OPENDLP_DB_USER` | MySQL database username | `OpenDLP` |
| `OPENDLP_DB_PASS` | MySQL database password | `password` |
| `DB_HOST` | MySQL database host | `127.0.0.1` |
| `DB_PORT` | MySQL database port | `3306` |
| `DB_NAME` | MySQL database name | `OpenDLP` |

> The container automatically checks the database on startup, creates it if missing, and initializes the schema if empty using `create.sql`.

### 🗄 User Configuration

| Variable | Description | Default |
|---------|-------------|---------|
|`DLP_USER`|Username|`default_web_user`|
|`DLP_PASS`|Username password|`default_web_pass`|
|`DLP_AGENT_USER`|DLP Agent Username|`default_agent_user`|
|`DLP_AGENT_PASS`|DLP Agent password|`default_agent_pass` |

### 🧩 Configuration File Auto-Update

If `DB_HOST` is not the default (`127.0.0.1`), the container will update OpenDLP configuration files to point to the provided host automatically.

## 🔄 CI/CD Pipeline Overview

This project uses a GitHub Actions workflow to:
- Build the Docker image for multiple architectures (`amd64`, `arm64`)
- Run a smoke test before pushing the image
- Push the image to Docker Hub with appropriate tags

See `.github/workflows/docker-build.yml` for full pipeline details.

## 📜 License

This project is licensed under the MIT License.
See the original [LICENSE](https://github.com/ezarko/opendlp/blob/main/LICENSE) from the upstream repository.

---

## ✅ Example Usage

If you're using your own database

```bash
docker run -e OPENDLP_DB_USER=admin -e OPENDLP_DB_PASS=secret \
           -e DB_HOST=10.10.10.10 \
           moophlo/opendlp:latest
```

If you want the database to be created automatically
```bash
docker compose up -d
```

From inside the folder in which the docker-compose.yaml file is, you want to grab from the container both the client an CA Certificates:
```bash
docker compose cp opendlp:/etc/ssl/opendlp/client.p12 client.p12
docker compose cp opendlp:/etc/ssl/opendlp/ca/demoCA/cacert.pem cacert.pem
```

The CA Certificates need to be imported in the trusted CA Certificates in your browser.
The Client Certificate need to be imported in the "Your Certificates" section in the browser

On the first connection to: https://localhost/OpenDLP/ when requested just select the Client Certificate

