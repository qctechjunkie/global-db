#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/backups"
RETENTION_DAYS=${RETENTION_DAYS:-7}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_SESSION_DIR="${BACKUP_DIR}/${TIMESTAMP}"

echo "$(date): Starting database backup session..."

# Create backup session directory
mkdir -p "${BACKUP_SESSION_DIR}"

# Get list of all databases except system databases
DATABASES=$(mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

if [ -z "$DATABASES" ]; then
    echo "$(date): No databases found to backup"
    rmdir "${BACKUP_SESSION_DIR}"
    exit 0
fi

# Backup each database separately
BACKUP_COUNT=0
TOTAL_SIZE=0
FAILED_BACKUPS=""

for DB in $DATABASES; do
    BACKUP_FILE="${BACKUP_SESSION_DIR}/${DB}.sql.gz"
    echo "$(date): Backing up database: ${DB}"

    if mysqldump -h"${MYSQL_HOST}" \
        -u"${MYSQL_USER}" \
        -p"${MYSQL_PASSWORD}" \
        --databases "${DB}" \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --routines \
        --triggers \
        --events \
        | gzip > "${BACKUP_FILE}"; then

        # Verify the gzip file is valid (not corrupted)
        if gzip -t "${BACKUP_FILE}" 2>/dev/null; then
            BACKUP_SIZE=$(stat -c%s "${BACKUP_FILE}" 2>/dev/null || echo "0")

            # Check that file is not empty
            if [ "${BACKUP_SIZE}" -gt 0 ]; then
                TOTAL_SIZE=$((TOTAL_SIZE + BACKUP_SIZE))
                BACKUP_COUNT=$((BACKUP_COUNT + 1))
                echo "$(date): ✓ ${DB} backed up successfully (${BACKUP_SIZE} bytes)"
            else
                echo "$(date): ✗ Backup file for ${DB} is empty" >&2
                rm -f "${BACKUP_FILE}"
                FAILED_BACKUPS="${FAILED_BACKUPS}${DB}(empty) "
            fi
        else
            echo "$(date): ✗ Backup file for ${DB} is corrupted" >&2
            rm -f "${BACKUP_FILE}"
            FAILED_BACKUPS="${FAILED_BACKUPS}${DB}(corrupted) "
        fi
    else
        echo "$(date): ✗ Failed to backup ${DB}" >&2
        FAILED_BACKUPS="${FAILED_BACKUPS}${DB} "
    fi
done

# Display summary
echo "$(date): ========================================"
echo "$(date): Backup session completed: ${TIMESTAMP}"
echo "$(date): Successfully backed up: ${BACKUP_COUNT} database(s)"

if [ -n "$FAILED_BACKUPS" ]; then
    echo "$(date): Failed backups: ${FAILED_BACKUPS}"
fi

# Convert total size to human readable
if [ ${TOTAL_SIZE} -gt 0 ]; then
    TOTAL_SIZE_MB=$((TOTAL_SIZE/1024/1024))
    echo "$(date): Total backup size: ${TOTAL_SIZE_MB} MB"
fi

# Delete old backup sessions
if [ "${RETENTION_DAYS}" -gt 0 ]; then
    echo "$(date): Removing backup sessions older than ${RETENTION_DAYS} days..."
    # Find directories matching timestamp pattern YYYYMMDD_HHMMSS
    find "${BACKUP_DIR}" -maxdepth 1 -type d -name "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]" -mtime +${RETENTION_DAYS} -exec rm -rf {} \; 2>/dev/null || true
    echo "$(date): Cleanup completed"
fi

# List current backup sessions
echo "$(date): Current backup sessions:"
ls -lht "${BACKUP_DIR}" | grep "^d" | grep -E "[0-9]{8}_[0-9]{6}" || echo "No backup sessions found"

echo "$(date): ========================================"

# Exit with error if any backups failed
if [ -n "$FAILED_BACKUPS" ]; then
    exit 1
fi
