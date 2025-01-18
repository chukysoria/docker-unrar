# syntax=docker/dockerfile:1@sha256:93bfd3b68c109427185cd78b4779fc82b484b0b7618e36d0f104d4d801e66d25

FROM ghcr.io/chukysoria/baseimage-alpine:v0.6.25-3.20@sha256:058af9b1f3e48f0f88e37ae6f0b155afe75388add18cb11af652df316954dbfa AS alpine-buildstage

# set version label
ARG BUILD_EXT_RELEASE="7.1.3"
COPY data.rar /data.rar

RUN \
  echo "**** install build dependencies ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${BUILD_EXT_RELEASE}.tar.gz" && \
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  sed -i 's|LDFLAGS=-pthread|LDFLAGS=-pthread -static|' makefile && \
  sed -i 's|CXXFLAGS=-march=native |CXXFLAGS=|' makefile && \
  make && \
  install -v -m755 unrar /usr/bin && \
  echo "**** test binary ****" && \
  /usr/bin/unrar v /data.rar && \
  /usr/bin/unrar t /data.rar && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /tmp/*


FROM ghcr.io/chukysoria/baseimage-ubuntu:v0.2.43-jammy@sha256:723e318cb08f68179ec1bf0e7d619e1ebf02da295ecb2890cacdc60eb817c6b5 AS ubuntu-buildstage

# set version label
ARG BUILD_EXT_RELEASE="7.1.3"
COPY data.rar /data.rar

RUN \
  echo "**** install build dependencies ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    g++ \
    make && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${BUILD_EXT_RELEASE}.tar.gz" && \  
    tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  sed -i 's|LDFLAGS=-pthread|LDFLAGS=-pthread -static|' makefile && \
  sed -i 's|CXXFLAGS=-march=native |CXXFLAGS=|' makefile && \
  make && \
  install -v -m755 unrar /usr/bin && \
  echo "**** test binary ****" && \
  /usr/bin/unrar v /data.rar && \
  /usr/bin/unrar t /data.rar && \
  echo "**** cleanup ****" && \
  apt-get remove -y \
    g++ \
    make && \
  apt-get -y autoremove && \
  apt-get clean && \
  rm -rf \
    /root/.cache \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*


# Storage layer consumed downstream
FROM scratch

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# Add files from buildstage
COPY --from=alpine-buildstage /usr/bin/unrar /usr/bin/unrar-alpine
COPY --from=ubuntu-buildstage /usr/bin/unrar /usr/bin/unrar-ubuntu
