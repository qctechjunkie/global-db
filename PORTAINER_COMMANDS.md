# Quick Command Reference for Portainer/VM

Copy-paste these commands directly on your VM.

## Initial Setup

```bash
# Navigate to project directory
cd /path/to/global-db

# Create .env from example
cp .env.example .env

# Edit passwords (both must match!)
nano .env
# Set: MYSQL_ROOT_PASSWORD and MYSQL_PASSWORD to the same value

# Build and start
docker compose up -d --build

# Verify all services running
docker compose ps
```

## Backup Commands

```bash
# Manual backup NOW
docker exec db-backup /usr/local/bin/backup.sh

# List all backup sessions
docker exec db-backup ls -lt /backups

# View databases in specific session
docker exec db-backup ls -lh /backups/20260108_143022
```

## Restore Commands

```bash
# List available backups first
docker exec db-backup /usr/local/bin/restore.sh

# Restore ONE database
docker exec -it db-backup /usr/local/bin/restore.sh 20260108_143022 database_name

# Restore ALL databases from session
docker exec -it db-backup /usr/local/bin/restore.sh 20260108_143022
```

## Database Access

```bash
# Access MySQL prompt
docker exec -it global-mariadb mysql -uroot -p

# Quick query without prompt
docker exec global-mariadb mysql -uroot -p'YOUR_PASSWORD' -e "SHOW DATABASES;"
```

## Monitoring

```bash
# View backup logs (live)
docker compose logs -f db-backup

# View last 50 lines
docker compose logs --tail=50 db-backup

# Check cron schedule
docker exec db-backup crontab -l

# View cron logs
docker exec db-backup tail -50 /var/log/cron.log
```

## Troubleshooting

```bash
# Restart backup service
docker compose restart db-backup

# Rebuild if you changed scripts
docker compose up -d --build db-backup

# Check if backups directory has files
docker exec db-backup ls -la /backups

# Verify .env passwords match
cat .env | grep PASSWORD
```

## Copy Backups to Host

```bash
# Copy specific database backup to current directory
docker cp db-backup:/backups/20260108_143022/my_database.sql.gz ./

# Copy entire backup session
docker cp db-backup:/backups/20260108_143022 ./backups/
```
