#!/bin/bash

BASE_DIR="/tmp/nas"
TEMP_MOUNT="/mnt/.folder_name2_temp"

SHARE_STORAGE="//ip_address/folder_name"
SHARE_LEGACY="//ip_address/folder_name2"

DOMAIN=""

# Очистка старых монтирований
echo "Очистка старых монтирований"
sudo umount -l "$BASE_DIR"/* 2>/dev/null
sudo umount -l "$TEMP_MOUNT" 2>/dev/null

# Запрос логина и пароля
read -r -p "Введите имя пользователя: " USER
read -s -p "Введите пароль: " PASS
echo ""

if [ -z "$USER" ] || [ -z "$PASS" ]; then
    echo "Ошибка: Логин и пароль обязательны"
    exit 1
fi

# Учетные данные
CRED_FILE=$(mktemp)
chmod 600 "$CRED_FILE"
printf "username=%s\npassword=%s\n" "$USER" "$PASS" > "$CRED_FILE"
[ -n "$DOMAIN" ] && printf "domain=%s\n" "$DOMAIN" >> "$CRED_FILE"

MOUNT_OPTS="credentials=$CRED_FILE,uid=$(id -u),gid=$(id -g),iocharset=utf8,sec=ntlmssp,vers=3.0,cache=none"

echo "=================================================="

# 1. Монтируем folder_name напрямую по IP
sudo mkdir -p "$BASE_DIR/folder_name"
if sudo mount -t cifs -o "$MOUNT_OPTS" "$SHARE_STORAGE" "$BASE_DIR/folder_name"; then
    echo "Смонтировано: $BASE_DIR/folder_name (напрямую)"
else
    echo "Ошибка: $BASE_DIR/folder_name"
fi

# 2. Монтируем folder_name2 во временную папку
sudo mkdir -p "$TEMP_MOUNT"
if sudo mount -t cifs -o "$MOUNT_OPTS" "$SHARE_LEGACY" "$TEMP_MOUNT"; then
    echo "Смонтировано: $TEMP_MOUNT (folder_name2)"
    echo ""
    echo "Поиск папок внутри folder_name2"
    echo "--------------------------------------------------"
    
    # 3. Цикл по всем папкам внутри folder_name2
    MOUNTED_COUNT=0
    FAILED_COUNT=0
    SKIPPED_COUNT=0
    
    for folder in "$TEMP_MOUNT"/*; do
        if [ -d "$folder" ]; then
            folder_name=$(basename "$folder")
            target_path="$BASE_DIR/$folder_name"
            
            # Пропускаем папку Хранилище - она уже смонтирована напрямую
            if [ "$folder_name" = "Хранилище" ]; then
                echo "$folder_name (уже смонтирована напрямую)"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                continue
            fi
            
            # Создаем целевую папку
            sudo mkdir -p "$target_path"
            
            # Монтируем через bind
            if sudo mount --bind "$folder" "$target_path"; then
                echo "$folder_name"
                MOUNTED_COUNT=$((MOUNTED_COUNT + 1))
            else
                echo "$folder_name (ошибка монтирования)"
                FAILED_COUNT=$((FAILED_COUNT + 1))
            fi
        fi
    done
    
    echo "--------------------------------------------------"
    echo "Итого: смонтировано $MOUNTED_COUNT, пропущено $SKIPPED_COUNT, ошибок: $FAILED_COUNT"
    
else
    echo "Ошибка монтирования folder_name2"
fi

# Удаляем файл с паролем
rm -f "$CRED_FILE"

echo "=================================================="
echo "Готово. Содержимое $BASE_DIR:"
ls -l "$BASE_DIR"
echo "=================================================="
echo ""
echo "Для отключения всех монтирований:"
echo "  sudo umount -l $BASE_DIR/*"
echo "  sudo umount -l $TEMP_MOUNT"
