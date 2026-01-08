# Database Backup & Restore Guide

This setup includes automatic database backups with easy restore capabilities.

## Features

- **Separate backup files per database** for granular restore control
- **Automatic scheduled backups** using cron
- **Configurable retention policy** (delete old backups automatically)
- **Compressed backups** using gzip to save space
- **Easy restore** of individual databases or entire backup sessions
- **Manual backup/restore scripts** for on-demand operations

## Configuration

Edit your `.env` file with these backup settings:

```env
# Backup schedule (cron format)
BACKUP_SCHEDULE=0 2 * * *     # Daily at 2:00 AM

# Backup retention (days)
RETENTION_DAYS=7              # Keep backups for 7 days
```

### Backup Schedule Examples

- `0 2 * * *` - Daily at 2:00 AM
- `0 */6 * * *` - Every 6 hours
- `0 0 * * 0` - Weekly on Sunday at midnight
- `0 3 * * 1-5` - Weekdays at 3:00 AM
- `*/30 * * * *` - Every 30 minutes

## Getting Started

1. **Copy the example environment file:**
   ```bash
   copy .env.example .env
   ```

2. **Edit `.env` and update the passwords and settings**

3. **Build and start the services:**
   ```bash
   docker compose up -d --build
   ```

The backup service will:
- Run an initial backup immediately on startup
- Schedule automatic backups based on your cron schedule
- Automatically clean up old backups based on retention policy

## Manual Operations

### Run a Manual Backup

**Windows:**
```batch
db-backup.bat
```

**Linux/Mac or Docker command:**
```bash
docker compose exec db-backup /usr/local/bin/backup.sh
```

### List Available Backup Sessions

**Windows:**
```batch
db-list-backups.bat
```

**Linux/Mac or Docker command:**
```bash
docker compose exec db-backup ls -lt /backups
```

### List Databases in a Backup Session

**Windows:**
```batch
db-list-backups.bat 20260108_020000
```

**Linux/Mac or Docker command:**
```bash
docker compose exec db-backup ls -lh /backups/20260108_020000
```

### Restore from a Backup

**Restore all databases from a session:**

**Windows:**
```batch
db-restore.bat 20260108_020000
```

**Linux/Mac or Docker command:**
```bash
docker compose exec -it db-backup /usr/local/bin/restore.sh 20260108_020000
```

**Restore a specific database:**

**Windows:**
```batch
db-restore.bat 20260108_020000 my_database
```

**Linux/Mac or Docker command:**
```bash
docker compose exec -it db-backup /usr/local/bin/restore.sh 20260108_020000 my_database
```

The restore script will:
1. Show you what will be restored
2. Ask for confirmation (type "yes" to proceed)
3. Restore the specified database(s)

**WARNING:** Restoring will overwrite your current databases!

## Backup Storage

Backups are stored in a Docker volume named `db_backups`. This keeps them persistent even if containers are removed.

### Backup Structure

Backups are organized in timestamped session directories:
```
/backups/
├── 20260108_020000/
│   ├── database1.sql.gz
│   ├── database2.sql.gz
│   └── database3.sql.gz
├── 20260108_140000/
│   ├── database1.sql.gz
│   └── database2.sql.gz
```

Each backup session contains separate compressed files for each database.

### Accessing Backup Files

To copy a specific database backup to your host machine:

```bash
docker cp db-backup:/backups/20260108_020000/my_database.sql.gz ./
```

To copy an entire backup session:

```bash
docker cp db-backup:/backups/20260108_020000 ./backups/
```

### View Backup Logs

To see the backup service logs:

```bash
docker compose logs -f db-backup
```

## Backup File Format

Backup sessions are organized by timestamp:
```
YYYYMMDD_HHMMSS/
├── database_name.sql.gz
└── another_db.sql.gz
```

Example: `20260108_143022/`
- Date: 2026-01-08
- Time: 14:30:22

Each database within the session is saved as `database_name.sql.gz`

## Troubleshooting

### Check if backup service is running:
```bash
docker compose ps db-backup
```

### View backup logs:
```bash
docker compose logs db-backup
```

### Manually trigger a backup to test:
```bash
docker compose exec db-backup /usr/local/bin/backup.sh
```

### Check cron is working:
```bash
docker compose exec db-backup crontab -l
```

## Best Practices

1. **Test your backups regularly** by doing test restores
2. **Monitor backup logs** to ensure backups are completing successfully
3. **Copy critical backups** to external storage for disaster recovery
4. **Adjust retention policy** based on your storage capacity and needs
5. **Set appropriate backup schedules** based on how frequently your data changes

## Advanced: External Backup Storage

To save backups to your host machine, modify `compose.yaml`:

```yaml
  db-backup:
    volumes:
      - ./backups:/backups  # Use local directory instead of volume
```

Then create a `backups` directory in your project folder.
