#!/bin/bash
set -e

N8N_DIR=/opt/n8n
BACKUP_DIR=$N8N_DIR/backups
COMPOSE_FILE=$N8N_DIR/docker-compose.yml
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo "========================================"
echo "  n8n Update Script"
echo "  $(date)"
echo "========================================"
echo

# 1. Текущая версия
CURRENT=$(docker inspect n8n --format '{{.Config.Image}}' 2>/dev/null || echo 'не запущен')
info "Текущий образ: $CURRENT"
CURRENT_VER=$(docker exec n8n n8n --version 2>/dev/null || echo 'неизвестно')
info "Текущая версия: $CURRENT_VER"

# 2. Скачиваем новый stable образ
info "Скачиваю образ n8nio/n8n:stable ..."
OLD_IMAGE_ID=$(docker images n8nio/n8n:stable -q 2>/dev/null)
docker pull n8nio/n8n:stable
NEW_IMAGE_ID=$(docker images n8nio/n8n:stable -q)

if [ "$OLD_IMAGE_ID" = "$NEW_IMAGE_ID" ] && [ -n "$OLD_IMAGE_ID" ]; then
    warn "Образ не изменился. n8n уже на последней стабильной версии."
    read -p "Продолжить обновление? (y/n): " CONT
    if [ "$CONT" != "y" ]; then
        info "Отменено."
        exit 0
    fi
fi

# 3. Бэкап БД
info "Создаю бэкап базы данных..."
mkdir -p $BACKUP_DIR
sudo -u postgres pg_dump n8n_db > $BACKUP_DIR/n8n_db_$TIMESTAMP.sql
DB_SIZE=$(du -h $BACKUP_DIR/n8n_db_$TIMESTAMP.sql | cut -f1)
info "Бэкап БД: $BACKUP_DIR/n8n_db_$TIMESTAMP.sql ($DB_SIZE)"

# 4. Бэкап тома
info "Создаю бэкап тома n8n_data..."
docker run --rm -v n8n_data:/data -v $BACKUP_DIR:/backup alpine \
    tar czf /backup/n8n_data_$TIMESTAMP.tar.gz -C /data .
VOL_SIZE=$(du -h $BACKUP_DIR/n8n_data_$TIMESTAMP.tar.gz | cut -f1)
info "Бэкап тома: $BACKUP_DIR/n8n_data_$TIMESTAMP.tar.gz ($VOL_SIZE)"

# 5. Обновляем compose файл
info "Обновляю docker-compose.yml..."
sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:stable|' $COMPOSE_FILE

# 6. Пересоздаём контейнер
info "Останавливаю n8n..."
cd $N8N_DIR
docker compose down

info "Запускаю обновлённый n8n..."
docker compose up -d

# 7. Ждём запуска
info "Ожидаю запуска (до 60 сек)..."
for i in $(seq 1 12); do
    sleep 5
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:5678/ 2>/dev/null || echo '000')
    if [ "$HTTP_CODE" = "200" ]; then
        break
    fi
    echo -n "."
done
echo

# 8. Проверка
NEW_VER=$(docker exec n8n n8n --version 2>/dev/null || echo 'ошибка')
if [ "$HTTP_CODE" = "200" ]; then
    info "n8n успешно обновлён!"
    info "Версия: $CURRENT_VER -> $NEW_VER"
    echo
    docker ps --filter name=n8n --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
else
    error "n8n не отвечает (HTTP: $HTTP_CODE). Проверьте логи: docker logs n8n"
fi

# 9. Чистим старые образы
info "Удаляю неиспользуемые образы..."
docker image prune -f

# 10. Удаляем бэкапы старше 30 дней
find $BACKUP_DIR -name '*.sql' -mtime +30 -delete 2>/dev/null
find $BACKUP_DIR -name '*.tar.gz' -mtime +30 -delete 2>/dev/null
info "Старые бэкапы (>30 дней) удалены."

echo
echo "========================================"
echo "  Обновление завершено!"
echo "  https://n8n2.remfara.com.ua"
echo "========================================"
