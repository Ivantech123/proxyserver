#!/bin/bash

# Скрипт запуска прокси-сервера с оптимизацией и мониторингом

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_message "Запуск прокси-сервера"

# Применяем оптимизации к конфигурации HAProxy
log_message "Применение оптимизаций к конфигурации HAProxy"
/usr/local/bin/optimize_haproxy.sh

# Запускаем мониторинг в фоновом режиме
log_message "Запуск мониторинга ресурсов"
/usr/local/bin/monitor_proxy.sh &

# Запускаем HAProxy в foreground режиме
log_message "Запуск HAProxy"
exec haproxy -f /etc/haproxy/haproxy.cfg -W -db
