FROM ruby:latest AS web-builder

RUN mkdir /oxidized-web
WORKDIR /oxidized-web
RUN git clone https://github.com/ytti/oxidized-web.git .
RUN rake build

# Single-stage build of an oxidized container from phusion/baseimage-docker focal-1.2.0, derived from Ubuntu 20.04 (Focal Fossa)
FROM phusion/baseimage:focal-1.2.0 

# set up dependencies for the build process
RUN apt-get -yq update \
    && apt-get -yq --no-install-recommends install ruby ruby-dev libssl1.1 libssl-dev pkg-config make cmake libssh2-1 libssh2-1-dev git git-email libmailtools-perl g++ libffi-dev ruby-bundler libicu66 libicu-dev libsqlite3-0 libsqlite3-dev libmysqlclient21 libmysqlclient-dev libpq5 libpq-dev zlib1g zlib1g-dev libgit2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# dependencies for hooks
RUN gem install aws-sdk slack-ruby-client xmpp4r cisco_spark --no-document
RUN gem install rugged --no-document -- --with-ssh

# dependencies for sources
RUN gem install gpgme sequel sqlite3 mysql2 pg --no-document

# dependencies for inputs
RUN gem install net-tftp net-http-persistent mechanize --no-document

# dependencies for ssh-keys
RUN gem install rbnacl -v '<5.0' --no-document
RUN gem install bcrypt_pbkdf -v '<2.0' --no-document
RUN gem install ed25519 -v '>= 1.2, < 1.3'

# build and install oxidized
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized

# docker automated build gets shallow copy, but non-shallow copy cannot be unshallowed
RUN git fetch --unshallow || true
RUN cat lib/oxidized/version.rb
RUN rake install

# web interface
#RUN gem install oxidized-web --no-document
COPY --from=web-builder /oxidized-web/pkg/oxidized-web*.gem ./
RUN gem install ./oxidized-web*.gem

# clean up
WORKDIR /
RUN rm -rf /tmp/oxidized
RUN apt-get -yq --purge autoremove ruby-dev pkg-config make cmake ruby-bundler libssl-dev libssh2-1-dev libicu-dev libsqlite3-dev libmysqlclient-dev libpq-dev zlib1g-dev

# add runit services
COPY extra/oxidized.runit /etc/service/oxidized/run
COPY extra/auto-reload-config.runit /etc/service/auto-reload-config/run
COPY extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

EXPOSE 8888/tcp
