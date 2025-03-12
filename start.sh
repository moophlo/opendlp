#!/bin/bash -x
set -e

# --- Configuration ---

# Directory where certificates are stored.
CERT_DIR="/etc/ssl/opendlp"
mkdir -p "$CERT_DIR"

# Directory for the CA (kept separate)
CA_DIR="$CERT_DIR/ca"
mkdir -p "$CA_DIR"
CA_SUBJ="${CA_SUBJ:-/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=opendlp-ca}"

# Certificate details can be set via environment variables.
SERVER_SUBJ="${APACHE_SSL_SUBJ:-/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=localhost}"
CLIENT_SUBJ="${APACHE_CLIENT_SUBJ:-/C=US/ST=State/L=City/O=MyOrg/OU=Clients/CN=client}"
CERT_PASS="${APACHE_CERT_PASS:-password}"

# Path to the OpenSSL configuration file (if needed)
OPENSSL_CONFIG="${OPENSSL_CONFIG:-/etc/ssl/openssl.cnf}"

# Extract the database credentials from environment variables.
# Default values are "OpenDLP" for username and "password" for password if not set.
DB_USER="${OPENDLP_DB_USER:-OpenDLP}"
DB_PASS="${OPENDLP_DB_PASS:-password}"

# Database connection parameters (defaults can be overridden by environment)
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-OpenDLP}"

# --- CA Management Functions ---

check_ca() {
  # Expect CA certificate and key in CA_DIR/demoCA
  if [ ! -f "$CA_DIR/demoCA/cacert.pem" ] || [ ! -f "$CA_DIR/demoCA/private/cakey.pem" ]; then
    echo "Missing CA certificate or key."
    return 1
  fi
  # Optionally verify the CA certificate (for example, by checking expiration)
  if ! openssl x509 -in "$CA_DIR/demoCA/cacert.pem" -noout -dates >/dev/null 2>&1; then
    echo "CA certificate exists but is invalid."
    return 1
  fi
  return 0
}

generate_ca() {
  echo "Generating CA..."
  # Create the directory structure expected by CA.pl
  mkdir -p "${CA_DIR}/demoCA/private" "${CA_DIR}/demoCA/newcerts"

  # Change to CA directory for CA.pl
  cd "$CA_DIR"

  # Run CA.pl in non-interactive mode.
  # Note: CA.pl is designed for interactive use.
  openssl genrsa -aes256 -passout pass:${CERT_PASS} -out "${CA_DIR}/demoCA/private/cakey.pem" 4096
  openssl rsa -in "${CA_DIR}/demoCA/private/cakey.pem" -passin pass:${CERT_PASS} -out "${CA_DIR}/demoCA/private/cakey.pem"

  # Generate a self-signed CA certificate (valid for 10 years)
  openssl req -new -x509 -days 3650 -key "${CA_DIR}/demoCA/private/cakey.pem" -out "${CA_DIR}/demoCA/cacert.pem" -subj "${CA_SUBJ}"
  echo 1000 > demoCA/serial
  touch demoCA/index.txt
  cd "$CERT_DIR"
  echo "CA generation complete. CA certificate at $CA_DIR/demoCA/cacert.pem"
}

# --- Function to Generate Certificates ---

check_certificates() {
  local REQUIRED_FILES=("server.crt" "client.crt" "server.key" "client.key" "server.pem" "client.pem")
  for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$CERT_DIR/$file" ]; then
      echo "Missing certificate file: $file"
      return 1
    fi
  done
  # Optionally, verify the server certificate is signed by the CA.
  if ! openssl verify -CAfile "$CA_DIR/demoCA/cacert.pem" "$CERT_DIR/server.crt" >/dev/null 2>&1; then
    echo "Server certificate verification failed."
    return 1
  fi
  return 0
}

generate_certificates() {
  echo "Generating certificates..."

  # Generate server key with a passphrase, then remove the passphrase.
  openssl genrsa -aes256 -passout "pass:$CERT_PASS" -out "$CERT_DIR/server.key" 4096
  openssl rsa -in "$CERT_DIR/server.key" -passin "pass:$CERT_PASS" -out "$CERT_DIR/server.key"

  # --- Create a CSR for the server certificate ---
  openssl req -new -key "$CERT_DIR/server.key" -out "$CERT_DIR/server.csr" -subj "$SERVER_SUBJ"

  # --- Sign the server CSR using the CA ---
  cd "$CA_DIR"
  # Ensure the serial file is set appropriately (adjust as needed)
  openssl ca -batch -config "$OPENSSL_CONFIG" -in "$CERT_DIR/server.csr" \
    -cert demoCA/cacert.pem -keyfile demoCA/private/cakey.pem \
    -out "$CERT_DIR/server.crt" -days 1825
  cd "$CERT_DIR"

  # Generate client key with a passphrase, then remove the passphrase.
  openssl genrsa -aes256 -passout "pass:$CERT_PASS" -out "$CERT_DIR/client.key" 4096
  openssl rsa -in "$CERT_DIR/client.key" -passin "pass:$CERT_PASS" -out "$CERT_DIR/client.key"

  # Create a certificate signing request for the client.
  openssl req -new -key "$CERT_DIR/client.key" -out "$CERT_DIR/client.csr" \
    -subj "$CLIENT_SUBJ"

  # Sign the client certificate request using the server certificate as the CA.
  # The -batch flag prevents interactive prompts.
  cd "$CA_DIR"
  openssl ca -batch -config "$OPENSSL_CONFIG" -in "$CERT_DIR/client.csr" \
    -cert "$CERT_DIR/server.crt" -keyfile "$CERT_DIR/server.key" \
    -out "$CERT_DIR/client.crt" -days 9999
  cd "$CERT_DIR"

  # Create a PKCS12 bundle for the client certificate and key.
  openssl pkcs12 -export -in "$CERT_DIR/client.crt" -inkey "$CERT_DIR/client.key" \
    -out "$CERT_DIR/client.p12" -passout "pass:$CERT_PASS"

  # Convert the client PKCS12 bundle to a PEM file (without encryption).
  openssl pkcs12 -in "$CERT_DIR/client.p12" -out "$CERT_DIR/client.pem" -nodes \
    -passin "pass:$CERT_PASS"

  # Create a PKCS12 bundle for the server certificate and key.
  openssl pkcs12 -export -in "$CERT_DIR/server.crt" -inkey "$CERT_DIR/server.key" \
    -out "$CERT_DIR/server.p12" -passout "pass:$CERT_PASS"

  # Convert the server PKCS12 bundle to a PEM file (without encryption).
  openssl pkcs12 -in "$CERT_DIR/server.p12" -out "$CERT_DIR/server.pem" -nodes \
    -passin "pass:$CERT_PASS"

  echo "Certificate generation complete."
}

# --- Main Certificate/CA Management Section ---

if ! check_ca; then
  echo "CA is missing or invalid. Generating CA..."
  generate_ca
else
  echo "CA exists and is valid."
fi

if ! check_certificates; then
  echo "Certificates missing or invalid. Generating certificates..."
  generate_certificates
else
  echo "All certificates exist and are valid."
fi

mkdir -p /var/www/localhost/OpenDLP/bin/
cp ${CERT_DIR}/server.pem /var/www/localhost/OpenDLP/bin/server.pem
cp ${CERT_DIR}/client.pem /var/www/localhost/OpenDLP/bin/client.pem

# --- Set Up Database Credentials File ---


# Ensure the target directory exists.
mkdir -p /var/www/localhost/OpenDLP/etc

# Write the credentials into /var/www/localhost/OpenDLP/etc/db_admin in the format "username:password"
echo "${DB_USER}:${DB_PASS}" > /var/www/localhost/OpenDLP/etc/db_admin
echo "Database credentials written to /var/www/localhost/OpenDLP/etc/db_admin"

# --- Database Check and Initialization ---


echo "Checking database '$DB_NAME' on ${DB_HOST}:${DB_PORT}..."

# Try to get the count of tables in the specified database.
TABLE_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -N -B -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME';" 2>/dev/null || echo "")

# If connection fails or TABLE_COUNT is empty, attempt to create the database.
if [ -z "$TABLE_COUNT" ]; then
  echo "Unable to connect to database '$DB_NAME' or it does not exist. Creating database..."
  mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
  TABLE_COUNT=0
fi

if [ "$TABLE_COUNT" -eq 0 ]; then
  echo "Database '$DB_NAME' is empty. Initializing structure from create.sql..."
  mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < /var/www/localhost/OpenDLP/sql/create.sql
else
  echo "Database '$DB_NAME' already contains tables. Skipping initialization."
fi

# --- Update Configuration Files with the Database Host ---

# If the provided DB_HOST is not the default (127.0.0.1), update configuration files.
if [ "$DB_HOST" != "127.0.0.1" ]; then
  echo "Updating configuration files to replace 'host=127.0.0.1' with 'host=$DB_HOST'..."
  # Find all files under /var/www/localhost/OpenDLP and replace "host=127.0.0.1" with the provided DB_HOST.
  find /var/www/localhost/OpenDLP -type f -exec sed -i "s/host=127\.0\.0\.1/host=$DB_HOST/g" {} +
  echo "Configuration files updated."
fi

# --- Start Apache or Override with Command-Line Arguments ---

echo "Starting Apache..."

# If arguments were passed to the container, execute them.
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  # Otherwise, run the default Apache startup command.
  exec apache2-foreground
fi
