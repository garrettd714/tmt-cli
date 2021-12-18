# syntax=docker/dockerfile:1
# Use alpine/python as the base. Alpine 3.14 for Ruby 2.7.5
FROM python:3.9.9-alpine3.14
LABEL maintainer="garrett.davis@protonmail.com"
ENV BUILD_PACKAGES bash curl-dev build-base sqlite-dev git tzdata
ENV RUBY_PACKAGES ruby-io-console ruby-bundler ruby-bigdecimal ruby-json
# Update and install all of the required packages.
# At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add ruby-dev=2.7.5-r0 && \
    apk add ruby=2.7.5-r0 && \
    apk add $RUBY_PACKAGES && \
    cp /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    apk del tzdata && \
    rm -rf /var/cache/apk/* && \
    pip install git+https://github.com/boyan-soubachov/tastyworks_api.git@a54aa873e804c72374f6654a221904b0428b7fbf#egg=tastyworks --no-cache-dir

# Set working directory
WORKDIR /tmt-cli/app

# Copy over just enough files to install Gems
COPY Gemfile ./
COPY Gemfile.lock ./
COPY tmt.gemspec ./
COPY lib/tmt/version.rb ./lib/tmt/

# bundle install
RUN bundle config --global silence_root_warning 1 && \
    bundle config set --local without 'development test' && \
    bundle install
