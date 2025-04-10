FROM alpine:3.16 AS build

# Установка только необходимых пакетов для сборки
RUN apk add --no-cache \
    haproxy \
    openssl \
    certbot \
    bash \
    curl \
    bc \
    htop \
    procps \
    net-tools

# Оптимизация настроек системы для производительности и низкого потребления ресурсов
RUN echo "net.core.somaxconn = 16384" >> /etc/sysctl.conf \
    && echo "net.ipv4.tcp_max_syn_backlog = 8192" >> /etc/sysctl.conf \
    && echo "net.ipv4.ip_local_port_range = 1024 65535" >> /etc/sysctl.conf \
    && echo "net.ipv4.tcp_fin_timeout = 15" >> /etc/sysctl.conf \
    && echo "net.ipv4.tcp_keepalive_time = 300" >> /etc/sysctl.conf \
    && echo "net.ipv4.tcp_max_tw_buckets = 32768" >> /etc/sysctl.conf \
    && echo "net.core.rmem_max = 8388608" >> /etc/sysctl.conf \
    && echo "net.core.wmem_max = 8388608" >> /etc/sysctl.conf

# Финальный образ
FROM alpine:3.16

# Установка только необходимых пакетов
RUN apk add --no-cache \
    haproxy \
    openssl \
    bash \
    curl \
    && rm -rf /var/cache/apk/*

# Create necessary directories with proper permissions
RUN mkdir -p /etc/haproxy/certs \
    /var/lib/haproxy \
    /var/log/haproxy \
    /var/log/haproxy/states \
    && chown -R haproxy:haproxy /var/lib/haproxy /var/log/haproxy

# Copy configuration files
COPY config/haproxy.cfg /etc/haproxy/haproxy.cfg
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/* \
    && sed -i 's/\r$//' /usr/local/bin/* # Исправление проблем с переносами строк Windows/Linux

# Expose ports
EXPOSE 80 443 3128-4128

# Set environment variables
ENV PROXY_COUNT=1000
ENV BASE_PORT=3128

# Настройка логирования и мониторинга с минимальным потреблением ресурсов
RUN touch /var/log/haproxy/monitor.log \
    && chown haproxy:haproxy /var/log/haproxy/monitor.log \
    && ln -sf /dev/stdout /var/log/haproxy/access.log \
    && ln -sf /dev/stderr /var/log/haproxy/error.log

# Оптимизация настроек HAProxy
COPY scripts/optimize_haproxy.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/optimize_haproxy.sh \
    && /usr/local/bin/optimize_haproxy.sh

# Настройка healthcheck с увеличенным интервалом для снижения нагрузки
HEALTHCHECK --interval=60s --timeout=3s --start-period=10s --retries=2 \
    CMD curl -f http://localhost:3128 || exit 1

# Start HAProxy with monitoring
CMD ["/usr/local/bin/start.sh"]
