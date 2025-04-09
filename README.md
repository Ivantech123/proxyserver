<div align="center">

# 🚀 Высокопроизводительный прокси-сервер

[![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg)](https://www.docker.com/)
[![HTTP/2](https://img.shields.io/badge/HTTP%2F2-Supported-green.svg)]()
[![PowerShell](https://img.shields.io/badge/PowerShell-Windows-blue.svg)]()
[![Bash](https://img.shields.io/badge/Bash-Linux-orange.svg)]()

Прокси-сервер на базе Docker с поддержкой HTTP/2, автоматической генерацией прокси и возможностями управления.

[Возможности](#-возможности) • [Установка](#-установка) • [Использование](#-использование)  • [Обновления](#-история-обновлений)

</div>

## 🌟 Возможности

<table>
  <tr>
    <td>🔒 <b>Безопасность</b></td>
    <td>🐳 <b>Docker</b></td>
    <td>⚡ <b>Производительность</b></td>
  </tr>
  <tr>
    <td>
      • SSL/TLS шифрование<br/>
      • Защищенные учетные данные<br/>
      • Изолированные контейнеры
    </td>
    <td>
      • Простое развертывание<br/>
      • Управление ресурсами<br/>
      • Кросс-платформенность
    </td>
    <td>
      • Поддержка HTTP/2<br/>
      • Балансировка нагрузки<br/>
      • Оптимизация соединений
    </td>
  </tr>
</table>

- ✅ Поддержка 1000-2500 одновременных прокси
- ✅ Автоматическая генерация прокси с уникальными учетными данными
- ✅ Инструменты управления учетными данными
- ✅ Оптимизация ресурсов для минимальных требований
- ✅ Интеграция с Telegram Stars для монетизации
- ✅ Поддержка Windows и Linux

## 💻 Системные требования

| Компонент | Минимальные | Рекомендуемые |
|-----------|-------------|---------------|
| CPU       | 2 ядра      | 4+ ядер       |
| RAM       | 2 ГБ        | 4+ ГБ         |
| Диск      | 40 ГБ SSD   | 100+ ГБ SSD   |
| Сеть      | 100 Мбит/с  | 1 Гбит/с      |
| ОС        | Windows 10+ / Ubuntu 20.04+ / Debian 11+ | Windows 11 / Ubuntu 22.04 |

## 📥 Установка

### Windows

1. Клонируйте репозиторий:
   ```powershell
   git clone https://github.com/Ivantech123/proxyserver.git
   cd proxyserver
   ```

2. Запустите установщик с правами администратора:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; .\install-and-run.ps1
   ```

3. Следуйте инструкциям в меню для:
   - Проверки системных требований
   - Установки необходимых компонентов
   - Генерации SSL-сертификатов
   - Запуска прокси-сервера

### Linux (Ubuntu/Debian)

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/Ivantech123/proxyserver.git
   cd proxyserver
   ```

2. Запустите установщик с правами root:
   ```bash
   sudo bash install-linux.sh
   ```

3. После установки управляйте сервером через:
   ```bash
   sudo proxymanage
   ```

## 🔧 Использование

### Управление прокси

#### Генерация новых прокси
```bash
docker exec proxy-server /usr/local/bin/generate_proxies.sh <количество> <базовый_порт>
```

#### Обновление учетных данных

Одиночный прокси:
```bash
docker exec proxy-server /usr/local/bin/update_credentials.sh single <порт> <новый_логин> <новый_пароль>
```

Массовое обновление:
```bash
docker exec proxy-server /usr/local/bin/update_credentials.sh bulk /path/to/credentials.csv
```

### Формат использования прокси

```
http://<логин>:<пароль>@<хост>:<порт>
```

Пример:
```
http://user123:pass456@proxy.example.com:3128
```

### Мониторинг производительности

```bash
# Просмотр использования ресурсов
docker stats proxy-server

# Проверка количества соединений
docker exec proxy-server ss -s

# Просмотр статистики HAProxy
docker exec proxy-server echo "show stat" | socat unix-connect:/var/lib/haproxy/stats stdio
```


## 🔍 Устранение неполадок

### Проблемы с соединением
- Проверьте логи HAProxy: `docker exec proxy-server tail -f /var/log/haproxy/access.log`
- Убедитесь, что порты доступны: `netstat -tuln | grep <порт>`
- Проверьте настройки брандмауэра: `ufw status` или `firewall-cmd --list-all`

### Проблемы с производительностью
- Мониторинг использования ресурсов: `docker stats proxy-server`
- Проверка лимитов соединений: `ulimit -n`
- Оптимизация настроек HAProxy в `haproxy.cfg`

### Проблемы с SSL
- Обновите сертификаты: 
  ```bash
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout certs/server.key -out certs/server.crt
  ```
- Проверьте права доступа: `chmod 644 certs/server.crt && chmod 600 certs/server.key`

## 📋 История обновлений

### Версия 2.0 (Апрель 2025)
- ✨ Добавлена поддержка Linux с автоматическим установщиком
- ✨ Интеграция с Telegram Stars API
- ✨ Улучшенный интерфейс управления с эмодзи и цветным выводом
- ✨ Оптимизированные bash-скрипты с индикаторами прогресса
- ✨ Расширенная диагностика системы и зависимостей
- 🐛 Исправлены ошибки в скрипте установки PowerShell
- 🐛 Улучшена обработка ошибок при установке зависимостей

### Версия 1.0 (Январь 2025)
- ✨ Первый публичный релиз
- ✨ Поддержка HTTP/2 и SSL/TLS
- ✨ Автоматическая генерация прокси
- ✨ Базовое управление учетными данными
- ✨ Контейнеризация Docker

## 📞 Поддержка

Если у вас возникли проблемы или вопросы:
1. Создайте issue на [GitHub](https://github.com/Ivantech123/proxyserver/issues)
2. Обратитесь к документации в папке `docs/`
3. Свяжитесь с разработчиком: [Ivantech123](https://github.com/Ivantech123)

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробности в файле [LICENSE](LICENSE).

---

<div align="center">

Сделано с ❤️ [Ivantech123](https://github.com/Ivantech123)

</div>
