FROM debian:12-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    haproxy \
    openssl \
    certbot \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /etc/haproxy/certs \
    /var/lib/haproxy \
    /var/log/haproxy

# Copy configuration files
COPY config/haproxy.cfg /etc/haproxy/haproxy.cfg
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Expose ports
EXPOSE 80 443 3128-4128

# Set environment variables
ENV PROXY_COUNT=1000
ENV BASE_PORT=3128

# Start HAProxy
CMD ["haproxy", "-f", "/etc/haproxy/haproxy.cfg"]
