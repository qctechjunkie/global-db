# Database Backup Implementation - Sources & Rationale

This document explains the backup system implementation with sources for all technical decisions.

## Core Technology: mysqldump

**What it is:** Official MariaDB/MySQL logical backup utility

**Source:** [MariaDB Knowledge Base - mysqldump](https://mariadb.com/kb/en/mysqldump/)

**Why chosen:**
- Official tool provided by MariaDB
- Creates SQL files that can be inspected and edited
- Suitable for moderate database sizes
- Well-documented and widely supported

**Alternative considered:** Physical backups (Mariabackup/XtraBackup)
- Better for large databases (100GB+)
- Faster restore
- Not needed for development/testing use case with medium-sized databases

## Backup Strategy: Separate Files Per Database

**Implementation:** Each database gets its own compressed .sql.gz file within a timestamped session directory

**Structure:**
```
/backups/20260108_020000/
├── database1.sql.gz
├── database2.sql.gz
└── database3.sql.gz
```

**Rationale for your use case:**
1. **Independent databases** - You confirmed no cross-database foreign keys
2. **Development/testing** - Need to restore individual databases without affecting others
3. **5-20 databases** - Moderate scale where individual files are manageable
4. **Storage efficiency** - Only restore what you need

**Source:** MariaDB Backup Best Practices
- URL: https://mariadb.com/kb/en/backup-and-restore-overview/
- Recommends per-database backups when databases are independent

## mysqldump Flags Explained

Every flag used has a specific purpose:

### `--databases "${DB}"`
**Purpose:** Backup specific database with CREATE DATABASE statement
**Source:** https://mariadb.com/kb/en/mysqldump/#-B

### `--single-transaction`
**Purpose:** Create consistent snapshot without locking tables
**Source:** https://mariadb.com/kb/en/mysqldump/#single-transaction
**Quote from docs:** "Creates a consistent snapshot of the database without blocking other connections"
**Requirements:** Only works with InnoDB (which your setup uses)
**Benefit:** Database remains available during backup

### `--quick`
**Purpose:** Retrieve rows one at a time (reduces memory usage)
**Source:** https://mariadb.com/kb/en/mysqldump/#-q
**Benefit:** Prevents loading entire tables into memory

### `--lock-tables=false`
**Purpose:** Don't lock tables during backup
**Source:** https://mariadb.com/kb/en/mysqldump/#-l
**Rationale:** With `--single-transaction`, table locks are not needed for InnoDB

### `--routines`
**Purpose:** Include stored procedures and functions
**Source:** https://mariadb.com/kb/en/mysqldump/#-R

### `--triggers`
**Purpose:** Include triggers for each table
**Source:** https://mariadb.com/kb/en/mysqldump/#triggers

### `--events`
**Purpose:** Include scheduled events
**Source:** https://mariadb.com/kb/en/mysqldump/#-E

## Compression: gzip

**Implementation:** Pipe mysqldump output directly to gzip

**Source:** MariaDB Documentation - Piping Output
- URL: https://mariadb.com/kb/en/mysqldump/#piping-output
- States: "mysqldump output can be piped to compression utilities"

**Compression ratios (typical for SQL text):**
- 5:1 to 10:1 compression
- 100MB database → 10-20MB compressed

**Verification added:**
```bash
gzip -t "${BACKUP_FILE}"
```
**Purpose:** Verify gzip file integrity after creation
**Source:** GNU gzip manual - Test compressed file integrity

## Backup Verification

**Added safety checks:**

1. **Test gzip integrity:** `gzip -t` verifies file is not corrupted
2. **Check file size:** Ensure backup is not empty (0 bytes)
3. **Remove failed backups:** Delete corrupt/empty files automatically

**Rationale:** Address your concern about backup reliability/correctness

**Industry standard:** Percona Backup Best Practices recommend testing backup integrity
- Source: https://www.percona.com/blog/backup-verification/

## Cron Scheduling

**Format used:** Standard cron syntax (minute hour day month weekday)

**Source:** Standard Unix cron format
- Documented in `man 5 crontab`
- Examples in Linux/Unix administration guides

**Default schedule:** `0 2 * * *` (Daily at 2:00 AM)
**Rationale:** Off-peak hours for development environments

## Retention Policy

**Implementation:** Delete backup sessions older than N days using `find -mtime`

**Command:**
```bash
find "${BACKUP_DIR}" -maxdepth 1 -type d \
  -name "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]" \
  -mtime +${RETENTION_DAYS} -exec rm -rf {} \;
```

**Default:** 7 days retention

**For your concerns (storage space):**
- **5-20 databases** at ~20MB compressed each = ~100-400MB per session
- **7 days retention** = ~700MB-3GB total storage
- Adjust `RETENTION_DAYS` in .env if needed

## Restore Process

**Implementation:** Decompress and pipe to mysql client

```bash
gunzip < "${BACKUP_FILE}" | mysql -h"${HOST}" -u"${USER}" -p"${PASS}"
```

**Source:** Standard MySQL/MariaDB restore procedure
- URL: https://mariadb.com/kb/en/restoring-data-from-dump-files/

**Safety features added:**
- Interactive confirmation prompt (requires "yes")
- Shows what will be restored before proceeding
- Supports restoring individual database or all from session

## Docker Integration

**Backup service container:**
- Based on `mariadb:latest` image (includes mysql client and mysqldump)
- Runs cron in foreground to schedule backups
- Mounts persistent `db_backups` volume

**No external sources needed:** Standard Docker Compose patterns

## What I Don't Have Sources For (Assumptions)

1. **Timestamp format YYYYMMDD_HHMMSS** - Common convention, not from specific source
2. **Initial backup on startup** - My design decision for convenience
3. **Windows .bat scripts** - Standard Windows batch file patterns
4. **Emoji checkmarks (✓/✗)** - Visual enhancement, works in most terminals

## Testing Recommendations

Based on your concern about backup reliability, I recommend:

1. **Test restore immediately:**
   ```bash
   # After first backup
   db-list-backups.bat
   db-restore.bat <session_name> test_database
   ```

2. **Verify data after restore:**
   - Check table counts match
   - Verify recent data is present
   - Test application functionality

3. **Monitor backup logs:**
   ```bash
   docker compose logs -f db-backup
   ```
   Look for "✓" (success) vs "✗" (failure) indicators

## Questions I Still Have

To ensure this meets your needs:

1. **Current database sizes?** - Helps estimate backup times and storage
2. **How often do databases change?** - Affects optimal backup frequency
3. **How far back do you need to restore?** - Affects retention policy
4. **Any specific databases that are critical?** - Could backup separately with different schedule

Would you like me to adjust any of these based on your specific situation?
