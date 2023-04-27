#!/bin/bash
# Проверяем наличие root прав
SCRIPT_NAME=$(basename $BASH_SOURCE)
if [ `id -u` != 0 ]; then
    echo "$SCRIPT_NAME: This script must be executed with root privileges"
    exit 1
fi

################### CONFIG ###################
TODAY_DATE=$(date +'%Y%m%d_%H%M')
MY_IP=$(hostname -I | cut -f1 -d ' ') # Если вдруг необходимо писать в лог IP передающей машины в локальной сети
SSH_KEY="/home/admini/.ssh/id_rsa"

# Важно удалить только логи нашего скрипта, поэтому используем уникальный префикс для логов
LOG_NAME_PREFIX="my_beautiful_log"
LOCAL_LOG_FOLDER="/var/log"

TARGET_HOST="192.168.1.33"
TARGET_USER="admini"
TARGET_PATH="/var/log"

################### CODE ###################
# Создаем 2 непустых файла (по условию требуется создать несколько файлов) вида {LOG_NAME_PREFIX}.{TODAY_DATE}.{i}.log и размером в 1МВ
for i in {1..2}
do  
    FILE_NAME="$LOG_NAME_PREFIX.$TODAY_DATE.$i.log"

    # Создаем локальный файл из (псевдо)случайных данных. Вместо них может быть поток данных от приложения.
    dd if=/dev/urandom of=$LOCAL_LOG_FOLDER/$FILE_NAME bs=1M count=1 || echo "$SCRIPT_NAME: Failed to write to $LOCAL_LOG_FOLDER. Check for correct permissions and run script again."
    
    # Передаем его на целевую машину
    scp -i $SSH_KEY $LOCAL_LOG_FOLDER/$FILE_NAME $TARGET_USER@$TARGET_HOST:$TARGET_PATH
    # rsync не установлен
    # rsync -qzat -e "ssh -i $SSH_KEY" $LOCAL_LOG_FOLDER/$FILE_NAME $TARGET_USER@$TARGET_HOST:$TARGET_PATH
    
    # Проверяем старые логи и удаляем, если они были созданы более 7 дней назад. 
    ssh -i $SSH_KEY $TARGET_USER@$TARGET_HOST find $TARGET_PATH -mtime +7 -iname $LOG_NAME_PREFIX -delete
done