FROM --platform=${BUILDPLATFORM} ubuntu:22.04 as builder
ARG version
ARG TARGETPLATFORM
WORKDIR /unpack
COPY hashes.txt /unpack/hashes.txt
RUN \
  case ${TARGETPLATFORM} in \
    "linux/amd64") DL_TARGET="linux-x64" ;; \
    "linux/arm/v7") DL_TARGET="linux-armv7" ;; \
    "linux/arm64") DL_TARGET="linux-armv8" ;; \
  esac && \
  apt update && \
  apt install -y wget bzip2 && \
  wget https://downloads.getmonero.org/cli/monero-${DL_TARGET}-${version}.tar.bz2 && \
  sha256sum --check --ignore-missing hashes.txt && \
  tar -xvf monero-${DL_TARGET}-${version}.tar.bz2 && \
  mv monero-*-${version}/monero* . && \
  rm -rf monero-*-${version}*

FROM --platform=${TARGETPLATFORM} ubuntu:22.04 as result
RUN apt update && apt install -y wget && rm -rf /var/lib/apt/lists/*

COPY --from=builder /unpack/* /app/
WORKDIR /app
VOLUME /data

EXPOSE 18080 18081
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:18081/get_info || exit 1

CMD ["/app/monerod", "--data-dir=/data", "--non-interactive", "--restricted-rpc", "--rpc-bind-ip=0.0.0.0", "--confirm-external-bind", "--enable-dns-blocklist", "--no-zmq", "--out-peers=16"]
