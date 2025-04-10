/**
 * Основной JavaScript файл для веб-интерфейса прокси-сервера
 */

// Функция для показа уведомлений
function showNotification(message, type = 'info') {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    const container = document.querySelector('.container');
    container.insertBefore(alertDiv, container.firstChild);
    
    // Автоматическое скрытие уведомления через 5 секунд
    setTimeout(() => {
        const bsAlert = new bootstrap.Alert(alertDiv);
        bsAlert.close();
    }, 5000);
}

// Функция для копирования текста в буфер обмена
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showNotification('Текст скопирован в буфер обмена', 'success');
    }).catch(err => {
        console.error('Failed to copy: ', err);
        showNotification('Не удалось скопировать текст', 'danger');
    });
}

// Функция для форматирования чисел с разделителями
function formatNumber(number) {
    return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Функция для отправки AJAX запросов
async function sendRequest(url, method = 'GET', data = null) {
    try {
        const options = {
            method: method,
            headers: {
                'Content-Type': 'application/json'
            }
        };
        
        if (data && method !== 'GET') {
            options.body = JSON.stringify(data);
        }
        
        const response = await fetch(url, options);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('Error sending request:', error);
        throw error;
    }
}

// Функция для проверки статуса прокси-сервера
async function checkProxyStatus() {
    try {
        const response = await fetch('/api/system_stats');
        if (response.ok) {
            return true;
        }
        return false;
    } catch (error) {
        console.error('Error checking proxy status:', error);
        return false;
    }
}

// Функция для генерации случайного пароля
function generateRandomPassword(length = 12) {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+=<>?';
    let password = '';
    for (let i = 0; i < length; i++) {
        const randomIndex = Math.floor(Math.random() * charset.length);
        password += charset[randomIndex];
    }
    return password;
}

// Инициализация всех тултипов Bootstrap
document.addEventListener('DOMContentLoaded', function() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // Добавляем кнопку генерации случайного пароля, если она есть на странице
    const generatePasswordBtn = document.getElementById('generate-password');
    if (generatePasswordBtn) {
        generatePasswordBtn.addEventListener('click', function() {
            const passwordField = document.getElementById('edit-password');
            if (passwordField) {
                passwordField.value = generateRandomPassword();
            }
        });
    }
});
