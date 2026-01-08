# Backup/Restore Testing Guide - Portainer

This guide walks you through testing the backup and restore functionality.

## Prerequisites

1. SSH into your VM where the containers run
2. Navigate to the directory containing compose.yaml
3. Ensure you have a .env file (copy from .env.example if needed)

## Step 1: Setup Environment File

On your VM:

```bash
# Navigate to your docker compose directory
cd /path/to/global-db

# Copy example .env if you don't have one
cp .env.example .env

# Edit .env and set matching passwords
nano .env
# Make sure MYSQL_ROOT_PASSWORD and MYSQL_PASSWORD are the same
```

## Step 2: Build and Start Services

**Option A: Using Portainer UI**
1. Go to Portainer → Stacks → Your Stack
2. Click "Editor"
3. Ensure compose.yaml has the db-backup service
4. Click "Update the stack" with "Re-pull and redeploy" checked

**Option B: Using Command Line on VM**

```bash
# Stop existing stack
docker compose down

# Build and start with backup service
docker compose up -d --build

# Check all services are running
docker compose ps
```

Expected output:
```
NAME                 IMAGE                  STATUS
global-mariadb       mariadb:latest         Up
phpmyadmin          phpmyadmin:latest      Up
db-backup           (custom built)         Up
```

## Step 3: Create Test Database with Data

SSH into the MariaDB container:

```bash
# Enter MariaDB container
docker exec -it global-mariadb mysql -uroot -p
# Enter your password when prompted
```

Inside MySQL prompt, create test database:

```sql
-- Create test database
CREATE DATABASE test_backup_demo;
USE test_backup_demo;

-- Create table with sample data
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO users (name, email) VALUES
    ('Alice Johnson', 'alice@example.com'),
    ('Bob Smith', 'bob@example.com'),
    ('Charlie Brown', 'charlie@example.com');

-- Verify data
SELECT * FROM users;

-- Exit MySQL
EXIT;
```

You should see 3 users listed.

## Step 4: Run Manual Backup

```bash
# Run a manual backup
docker exec db-backup /usr/local/bin/backup.sh
```

Expected output:
```
Starting database backup session...
Backing up database: test_backup_demo
✓ test_backup_demo backed up successfully
========================================
Backup session completed: 20260108_HHMMSS
Successfully backed up: 1 database(s)
```

**Note the timestamp** (e.g., 20260108_143022) - you'll need this for restore.

## Step 5: List Backups to Verify

```bash
# List all backup sessions
docker exec db-backup ls -lt /backups

# View databases in the latest session (replace TIMESTAMP)
docker exec db-backup ls -lh /backups/20260108_143022
```

You should see `test_backup_demo.sql.gz`

## Step 6: Modify the Database

Let's change data to test restore:

```bash
# Enter MariaDB container again
docker exec -it global-mariadb mysql -uroot -p
```

```sql
USE test_backup_demo;

-- Delete a user
DELETE FROM users WHERE name = 'Alice Johnson';

-- Add a new user
INSERT INTO users (name, email) VALUES ('Dave Wilson', 'dave@example.com');

-- Verify changes (should show Bob, Charlie, Dave - NO Alice)
SELECT * FROM users;

EXIT;
```

## Step 7: Restore from Backup

```bash
# Restore the database (replace TIMESTAMP with your actual timestamp)
docker exec -it db-backup /usr/local/bin/restore.sh 20260108_143022 test_backup_demo
```

You'll see:
```
Restoring database 'test_backup_demo' from session 20260108_143022
WARNING: This will overwrite the 'test_backup_demo' database!
Are you sure you want to continue? (yes/no):
```

Type `yes` and press Enter.

Expected output:
```
✓ Database 'test_backup_demo' restored successfully
```

## Step 8: Verify Restore

```bash
# Check the database was restored
docker exec -it global-mariadb mysql -uroot -p
```

```sql
USE test_backup_demo;

-- Should show original 3 users: Alice, Bob, Charlie (Dave should be gone)
SELECT * FROM users;

EXIT;
```

**Success:** You should see Alice, Bob, and Charlie (the original data). Dave should be gone.

## Step 9: Test Full Session Restore

Let's test restoring all databases at once:

```bash
# This would restore ALL databases in the backup session
docker exec -it db-backup /usr/local/bin/restore.sh 20260108_143022
# Type 'no' to cancel since we're just testing
```

## Step 10: Check Automatic Backup Schedule

```bash
# View the backup service logs
docker compose logs db-backup

# Check cron schedule is configured
docker exec db-backup crontab -l
```

Should show: `0 2 * * * /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1`

## Step 11: Monitor Backup Logs

```bash
# Follow backup logs in real-time
docker compose logs -f db-backup

# Or view just recent logs
docker compose logs --tail=50 db-backup
```

## Cleanup Test Database (Optional)

```bash
docker exec -it global-mariadb mysql -uroot -p
```

```sql
DROP DATABASE test_backup_demo;
EXIT;
```

## Troubleshooting

### Backup service not starting
```bash
# Check service status
docker compose ps db-backup

# View detailed logs
docker compose logs db-backup

# Common issue: .env passwords don't match
# Verify MYSQL_ROOT_PASSWORD == MYSQL_PASSWORD in .env
```

### Can't connect to database
```bash
# Verify MariaDB is running
docker compose ps global-mariadb

# Check MariaDB logs
docker compose logs global-mariadb
```

### Restore fails with "Access denied"
```bash
# Check MYSQL_USER and MYSQL_PASSWORD in .env
# Must match the MariaDB root password
```

### Backup files not found
```bash
# Check backups directory exists and has files
docker exec db-backup ls -la /backups

# Check volume is mounted
docker inspect db-backup | grep -A 10 Mounts
```

## What Success Looks Like

✅ Backup creates timestamped directories with .sql.gz files
✅ Backup verification shows "✓" for each database
✅ Restore asks for confirmation before proceeding
✅ After restore, original data is recovered
✅ Modified data is overwritten with backup data
✅ Cron schedule is configured for automatic backups

## Next Steps

- Set your desired backup schedule in `.env` (BACKUP_SCHEDULE)
- Set retention policy in `.env` (RETENTION_DAYS)
- Consider copying critical backups to external storage
- Setup monitoring/alerts for backup failures
