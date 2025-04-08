# Высокопроизводительный прокси-сервер

Прокси-сервер на базе Docker с поддержкой HTTP/2, автоматической генерацией прокси и возможностями управления.

## Возможности

- Поддержка HTTP/2 с SSL/TLS
- Поддержка 1000-2500 одновременных прокси
- Автоматическая генерация прокси с уникальными учетными данными
- Инструменты управления учетными данными
- Контейнеризация Docker
- Оптимизация ресурсов для минимальных требований к оборудованию

## Системные требования

- Docker и Docker Compose
- 2 ядра CPU
- 2 ГБ оперативной памяти
- 40 ГБ SSD/NVME накопитель

## Быстрый старт

1. Запустите установщик:
```powershell
.\install-and-run.ps1
```

2. Generate SSL certificate:
```bash
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout certs/server.key -out certs/server.crt
cat certs/server.crt certs/server.key > certs/server.pem
```

3. Start the proxy server:
```bash
docker-compose up -d
```

4. Generate proxies:
```bash
docker exec proxy-server /usr/local/bin/generate_proxies.sh 1000
```

## Managing Proxies

### Generate New Proxies
```bash
docker exec proxy-server /usr/local/bin/generate_proxies.sh <count> <base_port>
```

### Update Credentials

Single proxy:
```bash
docker exec proxy-server /usr/local/bin/update_credentials.sh single <port> <new_username> <new_password>
```

Bulk update:
```bash
docker exec proxy-server /usr/local/bin/update_credentials.sh bulk /path/to/credentials.csv
```

## SSH Commands

Common SSH commands for managing the proxy server:

```bash
# View proxy list
docker exec proxy-server cat /etc/haproxy/proxies.txt

# Check HAProxy status
docker exec proxy-server haproxy -c -f /etc/haproxy/haproxy.cfg

# View logs
docker exec proxy-server tail -f /var/log/haproxy/access.log

# Restart proxy service
docker-compose restart proxy
```

## Performance Monitoring

Monitor proxy server performance:

```bash
# View resource usage
docker stats proxy-server

# Check connection count
docker exec proxy-server ss -s

# View HAProxy stats
docker exec proxy-server echo "show stat" | socat unix-connect:/var/lib/haproxy/stats stdio
```

## Security Notes

- Always change default credentials
- Regularly update SSL certificates
- Monitor access logs for suspicious activity
- Keep Docker and HAProxy updated to latest stable versions

## Troubleshooting

1. Connection issues:
   - Check HAProxy logs
   - Verify port availability
   - Confirm firewall settings

2. Performance issues:
   - Monitor resource usage
   - Check connection limits
   - Verify network configuration

## License

[Your License]
