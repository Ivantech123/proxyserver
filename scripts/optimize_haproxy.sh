#!/bin/bash

# Скрипт для оптимизации настроек HAProxy для уменьшения потребления ресурсов и предотвращения отключения пользователей

HAPROXY_CFG="/etc/haproxy/haproxy.cfg"
BACKUP_FILE="/etc/haproxy/haproxy.cfg.backup.$(date +%Y%m%d%H%M%S)"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Проверяем наличие файла конфигурации
if [ ! -f "$HAPROXY_CFG" ]; then
    log_message "Ошибка: Файл конфигурации HAProxy не найден: $HAPROXY_CFG"
    exit 1
fi

# Создаем резервную копию конфигурации
log_message "Создание резервной копии конфигурации: $BACKUP_FILE"
cp "$HAPROXY_CFG" "$BACKUP_FILE"

# Оптимизация глобальных настроек
log_message "Оптимизация глобальных настроек HAProxy"

# Проверяем, есть ли уже раздел global в конфиге
if grep -q "^global" "$HAPROXY_CFG"; then
    # Обновляем существующие настройки
    sed -i '/^global/,/^defaults/ {
        s/maxconn [0-9]*/maxconn 4000/
        s/nbproc [0-9]*/nbproc 2/
        /tune.ssl.default-dh-param/ s/[0-9]*/2048/
        /log /d
    }' "$HAPROXY_CFG"
    
    # Добавляем новые оптимизации в раздел global
    sed -i '/^global/a \
    log /dev/log local0 notice\
    log /dev/log local1 notice\
    tune.ssl.default-dh-param 2048\
    tune.bufsize 32768\
    tune.maxrewrite 1024\
    spread-checks 5\
    hard-stop-after 30s\
    nbthread 4\
    # Настройки для предотвращения отключения пользователей\
    tune.idle-pool.shared off\
    tune.idle-pool.maxidle 128\
    tune.idle-pool.maxlife 3600\
    tune.pipesize 32768' "$HAPROXY_CFG"
else
    # Если раздела global нет, добавляем его
    cat > "$HAPROXY_CFG.new" << EOF
global
    log /dev/log local0 notice
    log /dev/log local1 notice
    maxconn 4000
    nbproc 2
    nbthread 4
    tune.ssl.default-dh-param 2048
    tune.bufsize 32768
    tune.maxrewrite 1024
    spread-checks 5
    hard-stop-after 30s
    # Настройки для предотвращения отключения пользователей
    tune.idle-pool.shared off
    tune.idle-pool.maxidle 128
    tune.idle-pool.maxlife 3600
    tune.pipesize 32768

$(cat "$HAPROXY_CFG")
EOF
    mv "$HAPROXY_CFG.new" "$HAPROXY_CFG"
fi

# Оптимизация настроек по умолчанию
log_message "Оптимизация настроек по умолчанию"

# Проверяем, есть ли уже раздел defaults в конфиге
if grep -q "^defaults" "$HAPROXY_CFG"; then
    # Обновляем существующие настройки
    sed -i '/^defaults/,/^[a-z]/ {
        s/timeout connect [0-9]*/timeout connect 5000/
        s/timeout client [0-9]*/timeout client 3600000/
        s/timeout server [0-9]*/timeout server 3600000/
        s/timeout http-request [0-9]*/timeout http-request 30000/
        s/timeout http-keep-alive [0-9]*/timeout http-keep-alive 60000/
        s/timeout queue [0-9]*/timeout queue 60000/
        s/timeout tunnel [0-9]*/timeout tunnel 3600000/
        s/timeout client-fin [0-9]*/timeout client-fin 30000/
        s/timeout server-fin [0-9]*/timeout server-fin 30000/
    }' "$HAPROXY_CFG"
    
    # Добавляем новые оптимизации в раздел defaults
    sed -i '/^defaults/a \
    option http-server-close\
    option redispatch\
    option dontlognull\
    option http-buffer-request\
    retries 3\
    backlog 10000\
    maxconn 3000\
    timeout check 10s' "$HAPROXY_CFG"
else
    # Если раздела defaults нет, добавляем его после global
    sed -i '/^global/,/^[a-z]/ {
        /^[a-z]/ i\
defaults\
    mode http\
    log global\
    option http-server-close\
    option redispatch\
    option dontlognull\
    option http-buffer-request\
    retries 3\
    backlog 10000\
    maxconn 3000\
    timeout connect 5000\
    timeout client 3600000\
    timeout server 3600000\
    timeout http-request 30000\
    timeout http-keep-alive 60000\
    timeout queue 30000\
    timeout tunnel 3600000\
    timeout check 10s
    }
' "$HAPROXY_CFG"
fi

# Оптимизация настроек прокси-сервера
log_message "Оптимизация настроек прокси-сервера"

# Оптимизируем каждый frontend раздел
for frontend in $(grep -n "^frontend" "$HAPROXY_CFG" | cut -d: -f1); do
    next_section=$(tail -n +$((frontend+1)) "$HAPROXY_CFG" | grep -n "^[a-z]" | head -1 | cut -d: -f1)
    if [ -z "$next_section" ]; then
        next_section=$(wc -l "$HAPROXY_CFG" | cut -d' ' -f1)
    else
        next_section=$((frontend + next_section))
    fi
    
    # Проверяем, есть ли уже оптимизации в этом frontend
    if ! sed -n "${frontend},${next_section}p" "$HAPROXY_CFG" | grep -q "maxconn"; then
        # Добавляем оптимизации в frontend
        sed -i "${frontend}a\    maxconn 2000\n    option http-buffer-request\n    timeout client 30s" "$HAPROXY_CFG"
    fi
done

# Оптимизируем каждый backend раздел
for backend in $(grep -n "^backend" "$HAPROXY_CFG" | cut -d: -f1); do
    next_section=$(tail -n +$((backend+1)) "$HAPROXY_CFG" | grep -n "^[a-z]" | head -1 | cut -d: -f1)
    if [ -z "$next_section" ]; then
        next_section=$(wc -l "$HAPROXY_CFG" | cut -d' ' -f1)
    else
        next_section=$((backend + next_section))
    fi
    
    # Проверяем, есть ли уже оптимизации в этом backend
    if ! sed -n "${backend},${next_section}p" "$HAPROXY_CFG" | grep -q "http-reuse"; then
        # Добавляем оптимизации в backend
        sed -i "${backend}a\    option http-reuse safe\n    http-request cache-use proxy-cache\n    http-response cache-store proxy-cache\n    timeout connect 5s\n    timeout server 30s" "$HAPROXY_CFG"
    fi
done

# Добавляем кэширование, если его еще нет
if ! grep -q "cache proxy-cache" "$HAPROXY_CFG"; then
    # Добавляем раздел кэширования перед первым frontend
    first_frontend=$(grep -n "^frontend" "$HAPROXY_CFG" | head -1 | cut -d: -f1)
    sed -i "${first_frontend}i\cache proxy-cache\n    total-max-size 200\n    max-age 60\n\n" "$HAPROXY_CFG"
fi

log_message "Оптимизация HAProxy завершена. Резервная копия сохранена в $BACKUP_FILE"

# Проверяем конфигурацию на ошибки
log_message "Проверка конфигурации HAProxy на ошибки"
if command -v haproxy >/dev/null 2>&1; then
    if haproxy -c -f "$HAPROXY_CFG"; then
        log_message "Конфигурация проверена успешно"
    else
        log_message "ОШИБКА: Конфигурация содержит ошибки. Восстанавливаем из резервной копии"
        cp "$BACKUP_FILE" "$HAPROXY_CFG"
    fi
else
    log_message "Предупреждение: Команда haproxy не найдена. Проверка конфигурации не выполнена"
fi

exit 0
