FROM ruby:2.5.1

ARG RAILS_ENV

# Necessary for bundler to operate properly
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN gem install bundler

RUN apt-get update && apt-get upgrade -y && \
  apt-get install --no-install-recommends -y  \
  build-essential libpq-dev libreoffice imagemagick unzip ghostscript vim \
  qt5-default libqt5webkit5-dev xvfb xauth openjdk-8-jre --fix-missing

RUN mkdir /data
WORKDIR /data

# Pre-install gems so we aren't reinstalling all the gems when literally any
# filesystem change happens
ADD Gemfile /data
ADD Gemfile.lock /data
ADD hyrax-migrator.gemspec /data
RUN mkdir /data/build
ADD ./build/install_gems.sh /data/build
RUN mkdir -p /data/lib/hyrax/migrator
ADD ./lib/hyrax/migrator/version.rb /data/lib/hyrax/migrator
RUN ./build/install_gems.sh

# Add the application code
ADD . /data
