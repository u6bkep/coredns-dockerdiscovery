ARG GOLANG_VERS=1.24.1
ARG ALPINE_VERS=3.21

FROM golang:${GOLANG_VERS}-alpine${ALPINE_VERS} AS build

ARG CGO_ENABLED=1
ARG COREDNS_VERS=1.12.0

# Combine installation, cloning, and build steps to reduce layers
RUN apk --no-cache add binutils build-base git && \
    git clone --depth 1 --branch v${COREDNS_VERS} https://github.com/coredns/coredns.git

# Copy local files - keep separate as they change frequently
COPY --link . /go/coredns-dockerdiscovery

# Combine configuration and build steps
WORKDIR /go/coredns
RUN cp ../coredns-dockerdiscovery/plugin.cfg . && \
    go mod edit -replace github.com/kevinjqiu/coredns-dockerdiscovery=../coredns-dockerdiscovery && \
    go generate coredns.go && \
    go build -mod=mod -o=coredns && \
    strip -vs coredns

# Final stage with minimal image
FROM alpine:${ALPINE_VERS}
RUN apk --no-cache add ca-certificates
COPY --from=build /go/coredns/coredns /usr/local/bin/coredns

ENTRYPOINT ["/usr/local/bin/coredns"]