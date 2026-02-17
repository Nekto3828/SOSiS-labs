#!/usr/bin/env python3
"""
Программа для вывода текущего времени с заданной периодичностью
в зависимости от архитектуры процессора
"""

import time
import datetime
import platform
import os
import sys

def get_architecture():
    """Определение архитектуры процессора"""
    machine = platform.machine().lower()
    
    if 'x86_64' in machine or 'amd64' in machine:
        return 'x64'
    elif 'i386' in machine or 'i686' in machine or 'x86' in machine:
        return 'x86'
    elif 'arm' in machine or 'aarch64' in machine:
        return 'arm'
    else:
        return 'unknown'

def get_delay_by_architecture(arch):
    """Получение задержки в зависимости от архитектуры"""
    delays = {
        'x86': 10,   # каждые 10 секунд для x86
        'x64': 7,    # каждые 7 секунд для x64
        'arm': 3,    # каждые 3 секунды для ARM
        'unknown': 5 # по умолчанию 5 секунд
    }
    return delays.get(arch, 5)

def format_time(use_timestamp=False):
    """Форматирование текущего времени"""
    now = datetime.datetime.now()
    if use_timestamp:
        return str(now.timestamp())
    else:
        return now.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

def main():

    
    # Получаем архитектуру процессора
    arch = get_architecture()
    
    # Получаем задержку из переменной окружения (если задана)
    env_delay = os.environ.get('TIME_SLEEP')
    
    if env_delay:
        try:
            delay = int(env_delay)
            print(f"Используется задержка из переменной окружения: {delay} секунд")
        except ValueError:
            print(f"Ошибка: TIME_SLEEP должно быть числом. Используется значение по умолчанию.")
            delay = get_delay_by_architecture(arch)
    else:
        # Используем задержку в зависимости от архитектуры
        delay = get_delay_by_architecture(arch)
    
    # Проверяем необходимость вывода временного штампа
    use_timestamp = os.environ.get('USE_TIMESTAMP', 'false').lower() == 'true'
    
    print(f"Программа запущена")
    print(f"Архитектура процессора: {arch}")
    print(f"Платформа: {platform.platform()}")
    print(f"Интервал вывода: {delay} секунд")
    print(f"Формат времени: {'timestamp' if use_timestamp else 'datetime'}")
    print("-" * 50)
    
    try:
        while True:
            current_time = format_time(use_timestamp)
            print(f"[{arch}] Текущее время: {current_time}")
            sys.stdout.flush()  # Принудительный сброс буфера вывода
            time.sleep(delay)
    except KeyboardInterrupt:
        print("\nПрограмма остановлена")

if __name__ == "__main__":
    main()