FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
    curl \
    tar \
    git \
    build-essential \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

ARG HUGO_VERSION="0.126.1"
ARG HUGO_FILENAME="hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
ARG HUGO_DOWNLOAD_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_FILENAME}"

# Download, extract, and install Hugo
RUN curl -L "${HUGO_DOWNLOAD_URL}" -o /tmp/${HUGO_FILENAME} \
    && tar -xvzf /tmp/${HUGO_FILENAME} -C /tmp/ \
    && mv /tmp/hugo /usr/local/bin/hugo \
    && rm /tmp/${HUGO_FILENAME}

# Set the working directory inside the container
WORKDIR /app

# Expose Hugo's default development server port
EXPOSE 1313

# Command to run Hugo development server
# --bind 0.0.0.0 makes it accessible from outside the container
# --port 1313 is the default, but good to be explicit
# --disableFastRender is often necessary in Docker for reliable live reloading
# --source . ensures it builds from the current directory (which will be /app)
CMD ["hugo", "serve", "--bind", "0.0.0.0", "--port", "1313", "--disableFastRender", "--source", "."]

