# Use an official image with Apache
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
    apt-get install -y vim tdsodbc perl unzip openssl sshfs curl ca-certificates p7zip-full mysql-client build-essential \
    libmysqlclient-dev \
    freetds-dev \
    libcgi-pm-perl \
    libdbi-perl \
    libfilesys-smbclient-perl \
    libxml-writer-perl \
    libdbd-sybase-perl \
    libarchive-extract-perl \
    libarchive-zip-perl \
    libdata-messagepack-perl \
    libdbd-mysql-perl && \
    rm -rf /var/lib/apt/lists/*

# Copy the custom Apache virtual host config
COPY ./opendlp.conf /etc/apache2/sites-available/opendlp.conf
COPY ./localhost/OpenDLP/perl_modules/MSFRPC.pm /usr/local/share/perl/5.38.2/MSFRPC.pm
COPY ./localhost/OpenDLP/perl_modules/MetaPostModule.pm /usr/local/share/perl/5.38.2/MetaPostModule.pm
COPY ./localhost/OpenDLP/perl_modules/MetaSploiter.pm /usr/local/share/perl/5.38.2/MetaSploiter.pm

# Enable SSL module, configure Apache for PHP support, and enable our SSL site configuration
RUN a2enmod ssl && \
    a2enmod socache_shmcb && \
    a2enmod cgid && \
    a2dissite 000-default default-ssl && \
    a2ensite opendlp

# Install Perl modules
ENV PERL_MM_USE_DEFAULT=1
#RUN perl -MCPAN -e 'CPAN::Shell->install(qw(CGI DBI Filesys::SmbClient Proc::Queue XML::Writer MIME::Base64 DBD::Sybase Algorithm::LUHN Time::HiRes Digest::MD5 File::Path Archive::Extract Archive::Zip Data::MessagePack ExtUtils::MakeMaker ExtUtils::ParseXS DBD::mysql))'
RUN perl -MCPAN -e 'CPAN::Shell->install("Algorithm::LUHN")' && \
    perl -MCPAN -e 'CPAN::Shell->install("CPAN::DistnameInfo")' && \
    perl -MCPAN -e 'CPAN::Shell->install("LWP")' && \
    perl -MCPAN -e 'CPAN::Shell->install("Proc::Queue")'

# Copy your application into the default Apache document root
RUN mkdir /localhost
COPY ./localhost/ /localhost/


# Copy your application into the default Apache document root
RUN mkdir /localhost
COPY ./localhost/ /localhost/

# Copy your custom start script into the image
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Override the default command/entrypoint to use your run.sh
CMD ["/run.sh"]
