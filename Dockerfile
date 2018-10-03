FROM debian:jessie
MAINTAINER yigal@publysher.nl

# Install pygments (for syntax highlighting) 
RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends python-pygments git ca-certificates asciidoc \
	&& rm -rf /var/lib/apt/lists/*

# Download and install hugo
ENV HUGO_VERSION 0.49
ENV HUGO_BINARY hugo_${HUGO_VERSION}_Linux-64bit.deb


ADD https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} /tmp/hugo.deb
RUN dpkg -i /tmp/hugo.deb \
	&& rm /tmp/hugo.deb

# Create working directory
RUN mkdir -p /usr/share/blog
RUN mkdir -p /usr/share/html
WORKDIR /usr/share/blog