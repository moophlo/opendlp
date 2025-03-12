# Use an official PHP image with Apache
FROM ubuntu/apache2


LABEL maintainer="moophlo"
LABEL org.opencontainers.image.title="opendlp"
LABEL org.opencontainers.image.description="OpenDLP container image built automatically via GitHub Actions"
LABEL org.opencontainers.image.source="https://github.com/moophlo/opendlp"
LABEL org.opencontainers.image.licenses="MIT"

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$VCS_REF

# Install Vim (optional)
RUN apt-get update && \
    apt full-upgrade -y && \
    apt-get install -y vim tdsodbc perl unzip openssl sshfs curl ca-certificates p7zip-full mysql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy SSL certificate and key
#COPY server.crt /etc/ssl/opendlp/server.crt
#COPY server.key /etc/ssl/opendlp/server.key
#COPY server.pem /var/www/localhost/OpenDLP/bin/server.pem
#COPY client.pem /var/www/localhost/OpenDLP/bin/client.pem

# Copy the custom Apache virtual host config
COPY ./opendlp.conf /etc/apache2/sites-available/opendlp.conf

RUN mkdir -p /var/www/localhost/OpenDLP/sql
COPY ./create.sql /var/www/localhost/OpenDLP/sql/create.sql


# Enable SSL module, configure Apache for PHP support, and enable our SSL site configuration
RUN a2enmod ssl && \
    a2enmod socache_shmcb && \
    a2enmod cgid && \
    a2dissite 000-default default-ssl && \
    a2ensite opendlp

# Install Perl modules
ENV PERL_MM_USE_DEFAULT=1
RUN perl -MCPAN -e 'CPAN::Shell->install(qw(CGI DBI Filesys::SmbClient Proc::Queue XML::Writer MIME::Base64 DBD::Sybase Algorithm::LUHN Time::HiRes Digest::MD5 File::Path Archive::Extract Archive::Zip Data::MessagePack ExtUtils::MakeMaker ExtUtils::ParseXS DBD::mysql))'

# Install p7zip-full for extracting the Resource Kit Tools installer.
RUN apt-get update && \
    apt-get install -y p7zip-full && \
    rm -rf /var/lib/apt/lists/*

# Download the Windows Server 2003 Resource Kit Tools installer.
#RUN curl -L -o /tmp/WindowsServer2003-KB893803-v2-x86-ENU.exe "https://download.microsoft.com/download/9/7/A/97AD74B7-DF1E-4F73-A1D2-0A1E847EF5F3/WindowsServer2003-KB893803-v2-x86-ENU.exe"

# Extract the installer and copy sc.exe to /usr/local/bin (or any desired location).
#RUN 7z x /tmp/WindowsServer2003-KB893803-v2-x86-ENU.exe -o/tmp/resourcekit && \
#    # Locate sc.exe in the extracted folder. (Adjust the search path if needed.)
#    find /tmp/resourcekit -iname "sc.exe" -exec cp {} /var/www/localhost/OpenDLP/bin/sc.exe \; && \
#    chmod +x /var/www/localhost/OpenDLP/bin/sc.exe && \
#    # Clean up temporary files
#    rm -rf /tmp/WindowsServer2003-KB893803-v2-x86-ENU.exe /tmp/resourcekit

# Copy your PHP application into the default Apache document root
COPY ./localhost/ /var/www/

# Copy your custom start script into the image
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Override the default command/entrypoint to use your start.sh
CMD ["/start.sh"]
