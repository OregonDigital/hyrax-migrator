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

# install FITS for file characterization
RUN mkdir -p /opt/fits && \
  curl -fSL -o /opt/fits-1.0.5.zip http://projects.iq.harvard.edu/files/fits/files/fits-1.0.5.zip && \
  cd /opt && unzip fits-1.0.5.zip && chmod +X fits-1.0.5/fits.sh

# install Kakadu for jp2 derivatives
RUN curl -fSL -o /opt/kakadu.zip http://kakadusoftware.com/wp-content/uploads/2014/06/KDU7A2_Demo_Apps_for_Ubuntu-x86-64_170827.zip && \
  cd /opt && unzip kakadu.zip && mv KDU7A2_Demo_Apps_for_Ubuntu-x86-64_170827 kakadu
ENV PATH="/opt/kakadu:${PATH}"
ENV LD_LIBRARY_PATH="/opt/kakadu:${LD_LIBRARY_PATH}"

RUN mkdir /data
WORKDIR /data

# Add the application code
ADD . /data

RUN ./build/install_gems.sh

CMD ["bash"]
