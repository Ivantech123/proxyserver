FROM python:3.9-alpine AS builder

WORKDIR /app

# Установка зависимостей для сборки
RUN apk add --no-cache gcc python3-dev musl-dev

# Установка зависимостей с кэшированием и оптимизацией
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Итоговый образ - используем минимальный Alpine
FROM python:3.9-alpine

WORKDIR /app

# Установка минимальных зависимостей
RUN apk add --no-cache curl

# Копирование зависимостей из сборочного образа
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Копирование только необходимых файлов приложения
COPY app.py config.py ./
COPY templates templates/
COPY static static/

# Открытие порта
EXPOSE 8080

# Настройка кэширования для Flask
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1
# Оптимизация памяти Python
ENV PYTHONOPTIMIZE=2

# Настройка healthcheck с увеличенным интервалом
HEALTHCHECK --interval=60s --timeout=3s --start-period=10s --retries=2 \
    CMD curl -f http://localhost:8080 || exit 1

# Запуск приложения с минимальным количеством процессов и потоков
CMD ["gunicorn", "--workers=2", "--threads=2", "--bind=0.0.0.0:8080", "--timeout=30", "--max-requests=1000", "--max-requests-jitter=50", "app:app"]
