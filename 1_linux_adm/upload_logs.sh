#!/bin/bash
# Данный скрипт может работать и с sudo правами, и без них.
# Для работы без sudo требует предварительной настройки передающей(1) и принимающей(2) сторон.
#
# 1.На первой машине настроить права для записи в /var/log:
#   1.1 Через chmod
#   1.2 Через группу с возможностью записи в /var/log (звучит безопаснее чем 1 вариант)
#
# 2.На принимающей машине:
#   2.1 Настроить SSH-доступ к пользователю с минимальными возможными правами в системе, и правами на запись логов в целевую папку

################### CONFIG ########################
TODAY_DATE=$(date +'%Y%m%d_%H%M')
MY_IP=$(hostname -I | cut -f1 -d ' ') # Если вдруг необходимо писать в лог IP передающей машины в локальной сети

# Исходим из предположения, что скрипт выполняется пользователем со своей домашней директорией, и настроенным SSH
# Если скрипт выполняется через sudo, то получаем домашнюю директорию пользователя через $SUDO_USER
if [ `id -u` = 0 ]; then
    SSH_KEY="/home/$SUDO_USER/.ssh/id_rsa"
else
    SSH_KEY="/home/$USER/.ssh/id_rsa" 
fi

# Важно удалить только логи нашего скрипта, поэтому используем уникальный префикс для логов
LOG_FOLDER="/var/log"
LOG_NAME_PREFIX="my_beautiful_log"

# Данные о целевой машине для отправки логов
TARGET_HOST="192.168.1.42"
TARGET_USER="admini"
TARGET_PATH="/var/log"

################### CODE ###################
# Создаем 2 непустых файла (по условию требуется создать несколько файлов) вида {LOG_NAME_PREFIX}.{TODAY_DATE}.{i}.log и размером в 1МВ
for i in {1..2}
do  
    FILE_NAME="$LOG_NAME_PREFIX.$TODAY_DATE.$i.log"

    # Создаем локальный файл из (псевдо)случайных данных. Вместо них могут быть данные от приложения
    dd if=/dev/urandom of=$LOG_FOLDER/$FILE_NAME bs=1M count=1 || echo "Failed to write to $LOG_FOLDER. Check for correct permissions and run script again."
    
    # Передаем его на целевую машину
    scp -i $SSH_KEY $LOCAL_LOG_FOLDER/$FILE_NAME $TARGET_USER@$TARGET_HOST:$TARGET_PATH
    # rsync не установлен
    # rsync -qzat -e "ssh -i $SSH_KEY" $LOG_FOLDER/$FILE_NAME $TARGET_USER@$TARGET_HOST:$TARGET_PATH
    
    # Проверяем старые логи и удаляем, если они были созданы более 7 дней назад. 
    ssh -i $SSH_KEY $TARGET_USER@$TARGET_HOST find $TARGET_PATH -mtime +7 -iname $LOG_NAME_PREFIX -delete
done