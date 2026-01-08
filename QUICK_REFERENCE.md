# Quick Reference - Database Backup Commands

## Setup

```batch
# Create .env file from example
copy .env.example .env

# Edit .env and update passwords (MYSQL_ROOT_PASSWORD and MYSQL_PASSWORD should match)

# Start services
docker compose up -d --build
```

## Common Operations

### List All Backup Sessions
```batch
db-list-backups.bat
```
Shows all backup sessions with timestamps like `20260108_020000`

### List Databases in a Session
```batch
db-list-backups.bat 20260108_020000
```
Shows individual database backup files in that session

### Manual Backup
```batch
db-backup.bat
```
Creates a new backup session immediately

### Restore All Databases
```batch
db-restore.bat 20260108_020000
```
Restores all databases from the specified backup session

### Restore Single Database
```batch
db-restore.bat 20260108_020000 wordpress_db
```
Restores only `wordpress_db` from the backup session

### View Backup Logs
```batch
docker compose logs -f db-backup
```

### Stop/Start Services
```batch
docker compose down
docker compose up -d
```

## Backup Structure

```
/backups/
├── 20260108_020000/          ← Backup session (timestamp)
│   ├── wordpress_db.sql.gz
│   ├── shop_db.sql.gz
│   └── blog_db.sql.gz
├── 20260108_140000/
│   ├── wordpress_db.sql.gz
│   └── shop_db.sql.gz
```

## Configuration (.env file)

```env
# Backup schedule (cron format)
BACKUP_SCHEDULE=0 2 * * *     # Daily at 2:00 AM

# How many days to keep backups
RETENTION_DAYS=7              # Keep for 7 days
```

### Schedule Examples
- `0 2 * * *` - Daily at 2:00 AM
- `0 */6 * * *` - Every 6 hours
- `0 0 * * 0` - Weekly on Sunday
- `*/30 * * * *` - Every 30 minutes
