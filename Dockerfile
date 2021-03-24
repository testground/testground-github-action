## Copy the binary from testground

# ARG TG_VERSION=v0.5.1
ARG TG_VERSION=edge
FROM iptestground/testground:${TG_VERSION}

## Runtime env

FROM alpine
RUN apk add jq
COPY --from=0 /testground /testground
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
