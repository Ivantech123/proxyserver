#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import subprocess
import secrets
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from functools import wraps
from datetime import datetime

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

# Конфигурация
ADMIN_USERNAME = os.environ.get('PROXY_ADMIN_USER', 'admin')
ADMIN_PASSWORD = os.environ.get('PROXY_ADMIN_PASS', 'admin')
PROXY_CONFIG_PATH = os.environ.get('PROXY_CONFIG_PATH', '/etc/haproxy/haproxy.cfg')
PROXY_STATS_SOCKET = os.environ.get('PROXY_STATS_SOCKET', '/var/lib/haproxy/stats')

# Функция для выполнения команд
def run_command(command):
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        return {'success': True, 'output': result.stdout}
    except subprocess.CalledProcessError as e:
        return {'success': False, 'error': e.stderr}

# Декоратор для проверки авторизации
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            flash('Пожалуйста, войдите в систему', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Маршруты
@app.route('/')
def index():
    # Автоматически авторизуем пользователя
    session['logged_in'] = True
    session['username'] = 'admin'
    return redirect(url_for('dashboard'))

@app.route('/login')
def login():
    # Автоматически авторизуем пользователя
    session['logged_in'] = True
    session['username'] = 'admin'
    return redirect(url_for('dashboard'))

@app.route('/logout')
def logout():
    session.clear()
    flash('Вы вышли из системы', 'info')
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    # Получение статистики системы
    system_stats = {
        'cpu': run_command("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'")['output'].strip(),
        'memory': run_command("free -m | awk 'NR==2{printf \"%s/%sMB (%.2f%%)\\n\", $3,$2,$3*100/$2 }'")['output'].strip(),
        'disk': run_command("df -h | awk '$NF=="/"{printf \"%d/%dGB (%s)\\n\", $3,$2,$5}'")['output'].strip(),
        'uptime': run_command("uptime -p")['output'].strip(),
        'connections': run_command("ss -s | grep 'TCP:' | awk '{print $2}'")['output'].strip()
    }
    
    # Получение списка прокси
    proxies = get_proxies()
    
    return render_template('dashboard.html', stats=system_stats, proxies=proxies)

@app.route('/proxies')
@login_required
def proxies():
    proxies = get_proxies()
    return render_template('proxies.html', proxies=proxies)

@app.route('/api/proxies', methods=['GET'])
@login_required
def api_get_proxies():
    proxies = get_proxies()
    return jsonify(proxies)

@app.route('/api/generate_proxies', methods=['POST'])
@login_required
def api_generate_proxies():
    count = request.form.get('count', 1, type=int)
    base_port = request.form.get('base_port', 3128, type=int)
    
    if count < 1 or count > 1000:
        return jsonify({'success': False, 'error': 'Количество должно быть от 1 до 1000'})
    
    result = run_command(f"docker exec proxy-server /usr/local/bin/generate_proxies.sh {count} {base_port}")
    
    if result['success']:
        flash(f'Успешно сгенерировано {count} прокси', 'success')
        return jsonify({'success': True, 'message': f'Успешно сгенерировано {count} прокси'})
    else:
        flash('Ошибка при генерации прокси', 'danger')
        return jsonify({'success': False, 'error': result['error']})

@app.route('/api/update_credentials', methods=['POST'])
@login_required
def api_update_credentials():
    port = request.form.get('port', type=int)
    username = request.form.get('username')
    password = request.form.get('password')
    
    if not all([port, username, password]):
        return jsonify({'success': False, 'error': 'Все поля обязательны'})
    
    result = run_command(f"docker exec proxy-server /usr/local/bin/update_credentials.sh single {port} {username} {password}")
    
    if result['success']:
        flash('Учетные данные успешно обновлены', 'success')
        return jsonify({'success': True, 'message': 'Учетные данные успешно обновлены'})
    else:
        flash('Ошибка при обновлении учетных данных', 'danger')
        return jsonify({'success': False, 'error': result['error']})

@app.route('/api/restart_proxy', methods=['POST'])
@login_required
def api_restart_proxy():
    result = run_command("docker restart proxy-server")
    
    if result['success']:
        flash('Прокси-сервер успешно перезапущен', 'success')
        return jsonify({'success': True, 'message': 'Прокси-сервер успешно перезапущен'})
    else:
        flash('Ошибка при перезапуске прокси-сервера', 'danger')
        return jsonify({'success': False, 'error': result['error']})

@app.route('/api/system_stats', methods=['GET'])
@login_required
def api_system_stats():
    system_stats = {
        'cpu': run_command("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'")['output'].strip(),
        'memory': run_command("free -m | awk 'NR==2{printf \"%s/%sMB (%.2f%%)\\n\", $3,$2,$3*100/$2 }'")['output'].strip(),
        'disk': run_command("df -h | awk '$NF=="/"{printf \"%d/%dGB (%s)\\n\", $3,$2,$5}'")['output'].strip(),
        'uptime': run_command("uptime -p")['output'].strip(),
        'connections': run_command("ss -s | grep 'TCP:' | awk '{print $2}'")['output'].strip(),
        'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }
    
    return jsonify(system_stats)

# Функция для получения списка прокси
def get_proxies():
    try:
        # Получаем список портов из конфигурации HAProxy
        config_result = run_command("docker exec proxy-server grep -E 'listen proxy_' /etc/haproxy/haproxy.cfg | awk '{print $2}' | sed 's/proxy_//'")
        
        if not config_result['success']:
            return []
        
        ports = config_result['output'].strip().split('\n')
        proxies = []
        
        for port in ports:
            if not port.strip():
                continue
                
            # Получаем учетные данные для каждого порта
            creds_result = run_command(f"docker exec proxy-server grep -A 5 'listen proxy_{port}' /etc/haproxy/haproxy.cfg | grep 'userlist' | head -1")
            
            if creds_result['success'] and creds_result['output'].strip():
                userlist = creds_result['output'].strip().split()[1]
                user_result = run_command(f"docker exec proxy-server grep -A 2 'userlist {userlist}' /etc/haproxy/haproxy.cfg | grep 'user'")
                
                if user_result['success'] and user_result['output'].strip():
                    user_line = user_result['output'].strip()
                    username = user_line.split()[1]
                    
                    # Статус прокси (активен/неактивен)
                    status_result = run_command(f"docker exec proxy-server ss -tlnp | grep ':{port}'")
                    status = 'active' if status_result['success'] and status_result['output'].strip() else 'inactive'
                    
                    proxies.append({
                        'port': port,
                        'username': username,
                        'status': status,
                        'url': f'http://{username}:*****@your-server-ip:{port}'
                    })
        
        return proxies
    except Exception as e:
        print(f"Error getting proxies: {e}")
        return []

# Запуск приложения
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
