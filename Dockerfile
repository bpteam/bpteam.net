# GitHub:       https://github.com/gohugoio
# Twitter:      https://twitter.com/gohugoio
# Website:      https://gohugo.io/

FROM golang:1.18-alpine AS build

# Optionally set HUGO_BUILD_TAGS to "extended" or "nodeploy" when building like so:
#   docker build --build-arg HUGO_BUILD_TAGS=extended .
ARG HUGO_BUILD_TAGS=extended

ARG CGO=1
ENV CGO_ENABLED=${CGO}
ENV GOOS=linux
ENV GO111MODULE=on


WORKDIR /go/src/github.com/gohugoio/hugo

# gcc/g++ are required to build SASS libraries for extended version
RUN apk update && \
    apk add --no-cache gcc g++ musl-dev git && \
    git clone --branch v0.97.3 --single-branch --depth 1 https://github.com/gohugoio/hugo.git . && \
    go install github.com/magefile/mage

RUN mage hugo && mage install

# ---

FROM alpine:3.12

COPY --from=build /go/bin/hugo /usr/bin/hugo

# libc6-compat & libstdc++ are required for extended SASS libraries
# ca-certificates are required to fetch outside resources (like Twitter oEmbeds)
RUN apk update && \
    apk add --no-cache ca-certificates libc6-compat libstdc++ git

# Expose port for live server
EXPOSE 1313

# Create working directory
RUN mkdir -p /usr/share/site
RUN mkdir -p /usr/share/html
WORKDIR /usr/share/site

CMD ["echo", "Hello, use docker-compose run --rm blog sh"]