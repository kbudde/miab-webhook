# syntax=docker/dockerfile:1

# Build stage. It always runs on the build platform so the Go toolchain can
# cross-compile for every target platform without needing emulators.
FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /src

COPY main.go go.mod go.sum ./

RUN --mount=type=cache,target=/go/pkg/mod \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOARM=${TARGETVARIANT#v} \
    go build -trimpath -ldflags "-s -w" -o /out/webhook .

# Runtime stage. The binary is fully static (CGO_ENABLED=0) and embeds the
# timezone database and root CA certificates, so a scratch image is enough.
FROM scratch

COPY --from=builder /out/webhook /webhook

USER 1000

ENTRYPOINT ["/webhook"]
CMD ["--secure-port=8443"]
