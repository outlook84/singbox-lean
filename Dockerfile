ARG GO_VERSION=1.24.0
FROM golang:${GO_VERSION}-alpine AS builder

COPY ./sing-box /go/src/github.com/sagernet/sing-box

WORKDIR /go/src/github.com/sagernet/sing-box

ENV CGO_ENABLED=0

ARG BUILD_TAGS

RUN set -ex \
    && apk add git build-base ca-certificates \
    && export COMMIT=$(git rev-parse --short HEAD) \
    && export VERSION=$(go run ./cmd/internal/read_tag) \
    && go build -v -trimpath -tags "${BUILD_TAGS}" -o /go/bin/sing-box \
       -ldflags "-X \"github.com/sagernet/sing-box/constant.Version=$VERSION\" -s -w -buildid=" \
       ./cmd/sing-box


FROM scratch

WORKDIR /etc/sing-box

COPY --from=builder /go/bin/sing-box /usr/local/bin/sing-box
COPY --from=builder /etc/ssl /etc/ssl
COPY --from=builder /etc/ca-certificates /etc/ca-certificates
COPY --from=builder /etc/ca-certificates.conf /etc/ca-certificates.conf

ENTRYPOINT ["sing-box"]