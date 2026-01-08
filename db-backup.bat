@echo off
REM Manual database backup script for Windows

echo Running manual database backup...
docker compose exec db-backup /usr/local/bin/backup.sh

echo.
echo Backup completed!
echo.
echo To list all backups, run:
echo docker compose exec db-backup ls -lh /backups
