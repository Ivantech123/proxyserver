#!/bin/bash

# Скрипт для мониторинга и автоматической перезагрузки прокси-сервера
# при превышении порогов использования ресурсов

CONTAINER_NAME="proxy-server"
CPU_THRESHOLD=85  # Порог использования CPU в процентах
MEM_THRESHOLD=85  # Порог использования памяти в процентах
CONN_THRESHOLD=2000  # Порог количества соединений
CHECK_INTERVAL=30  # Интервал проверки в секундах
MAX_CONSECUTIVE_FAILURES=3  # Максимальное количество последовательных превышений порога
LOG_FILE="/var/log/haproxy/monitor.log"  # Файл для логирования
ROTATE_SIZE=10M  # Размер файла логов для ротации

log_message() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
    
    # Ротация логов при превышении размера
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt $(echo $ROTATE_SIZE | sed 's/M/*1024*1024/' | bc) ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
        log_message "Лог-файл ротирован из-за превышения размера"
    fi
}

restart_container() {
    local reason="$1"
    log_message "Перезапуск контейнера $CONTAINER_NAME из-за: $reason"
    
    # Сохраняем текущее состояние перед перезапуском
    save_state
    
    # Перезапускаем контейнер
    docker restart $CONTAINER_NAME
    
    # Проверяем успешность перезапуска
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        log_message "Контейнер $CONTAINER_NAME успешно перезапущен"
        return 0
    else
        log_message "ОШИБКА: Не удалось перезапустить контейнер $CONTAINER_NAME"
        return 1
    fi
}

# Функция для сохранения текущего состояния перед перезапуском
save_state() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local state_dir="/var/log/haproxy/states"
    
    # Создаем директорию, если она не существует
    mkdir -p "$state_dir"
    
    # Сохраняем текущую статистику
    log_message "Сохранение текущего состояния в $state_dir/state_$timestamp.log"
    {
        echo "=== Состояние системы на $timestamp ==="
        echo ""
        echo "--- Использование CPU ---"
        top -bn1 | head -20
        echo ""
        echo "--- Использование памяти ---"
        free -m
        echo ""
        echo "--- Сетевые соединения ---"
        ss -tuln
        echo ""
        echo "--- Процессы HAProxy ---"
        ps aux | grep haproxy
    } > "$state_dir/state_$timestamp.log"
}

check_container_exists() {
    if ! docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        log_message "Контейнер $CONTAINER_NAME не найден или не запущен"
        return 1
    fi
    return 0
}

# Счетчик последовательных превышений порога
consecutive_failures=0

log_message "Запуск мониторинга для контейнера $CONTAINER_NAME"
log_message "Пороги: CPU: ${CPU_THRESHOLD}%, Память: ${MEM_THRESHOLD}%"
log_message "Интервал проверки: ${CHECK_INTERVAL} секунд"

while true; do
    # Проверяем существование контейнера
    if ! check_container_exists; then
        sleep $CHECK_INTERVAL
        continue
    fi
    
    # Получаем использование CPU
    cpu_usage=$(docker stats $CONTAINER_NAME --no-stream --format "{{.CPUPerc}}" | sed 's/%//')
    
    # Получаем использование памяти
    mem_usage=$(docker stats $CONTAINER_NAME --no-stream --format "{{.MemPerc}}" | sed 's/%//')
    
    log_message "Текущее использование ресурсов: CPU: ${cpu_usage}%, Память: ${mem_usage}%"
    
        # Получаем количество соединений
    conn_count=$(ss -tn | grep -c ESTAB)
    log_message "Количество активных соединений: $conn_count"
    
    # Проверяем превышение порогов
    resource_issue=false
    restart_reason=""
    
    # Проверка CPU
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        resource_issue=true
        restart_reason="высокая загрузка CPU ($cpu_usage%)"
        log_message "Предупреждение: Высокая загрузка CPU: $cpu_usage% > $CPU_THRESHOLD%"
    fi
    
    # Проверка памяти
    if (( $(echo "$mem_usage > $MEM_THRESHOLD" | bc -l) )); then
        resource_issue=true
        restart_reason="высокое использование памяти ($mem_usage%)"
        log_message "Предупреждение: Высокое использование памяти: $mem_usage% > $MEM_THRESHOLD%"
    fi
    
    # Проверка соединений
    if [ $conn_count -gt $CONN_THRESHOLD ]; then
        resource_issue=true
        restart_reason="слишком много соединений ($conn_count > $CONN_THRESHOLD)"
        log_message "Предупреждение: Слишком много соединений: $conn_count > $CONN_THRESHOLD"
    fi
    
    # Проверка работоспособности HAProxy
    if ! pgrep haproxy > /dev/null; then
        resource_issue=true
        restart_reason="процесс HAProxy не найден"
        log_message "КРИТИЧЕСКАЯ ОШИБКА: Процесс HAProxy не найден!"
    fi
    
    # Действия при обнаружении проблем
    if $resource_issue; then
        consecutive_failures=$((consecutive_failures + 1))
        log_message "Предупреждение: Проблемы с ресурсами (попытка $consecutive_failures/$MAX_CONSECUTIVE_FAILURES)"
        
        # Если превышен порог последовательных превышений, перезапускаем контейнер
        if [ $consecutive_failures -ge $MAX_CONSECUTIVE_FAILURES ]; then
            restart_container "$restart_reason"
            consecutive_failures=0
        fi
    else
        # Сбрасываем счетчик, если нагрузка нормальная
        if [ $consecutive_failures -gt 0 ]; then
            log_message "Нагрузка вернулась к нормальному уровню"
            consecutive_failures=0
        fi
    fi
    
    sleep $CHECK_INTERVAL
done
