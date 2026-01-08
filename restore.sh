#!/bin/bash
set -e

BACKUP_DIR="/backups"

# Function to list available backup sessions
list_backup_sessions() {
    echo "Available backup sessions:"
    ls -lt "${BACKUP_DIR}" | grep "^d" | grep -E "[0-9]{8}_[0-9]{6}" | awk '{print $NF}' || echo "No backup sessions found"
}

# Function to list databases in a backup session
list_session_databases() {
    local session="$1"
    echo "Databases in backup session ${session}:"
    ls -lh "${BACKUP_DIR}/${session}"/*.sql.gz 2>/dev/null | awk '{print $NF}' | xargs -n1 basename || echo "No databases found"
}

# Check if backup session/file is provided
if [ -z "$1" ]; then
    echo "Usage:"
    echo "  $0 <backup_session>                    - Restore all databases from a session"
    echo "  $0 <backup_session> <database_name>    - Restore specific database from a session"
    echo ""
    list_backup_sessions
    exit 1
fi

BACKUP_SESSION="$1"
SPECIFIC_DB="$2"
SESSION_DIR="${BACKUP_DIR}/${BACKUP_SESSION}"

# Check if backup session exists
if [ ! -d "${SESSION_DIR}" ]; then
    echo "Error: Backup session not found: ${BACKUP_SESSION}"
    echo ""
    list_backup_sessions
    exit 1
fi

# If specific database is requested
if [ -n "${SPECIFIC_DB}" ]; then
    # Remove .sql.gz extension if provided
    SPECIFIC_DB=$(echo "${SPECIFIC_DB}" | sed 's/\.sql\.gz$//')
    BACKUP_FILE="${SESSION_DIR}/${SPECIFIC_DB}.sql.gz"

    if [ ! -f "${BACKUP_FILE}" ]; then
        echo "Error: Database backup not found: ${SPECIFIC_DB}.sql.gz"
        echo ""
        list_session_databases "${BACKUP_SESSION}"
        exit 1
    fi

    echo "$(date): Restoring database '${SPECIFIC_DB}' from session ${BACKUP_SESSION}"
    echo "WARNING: This will overwrite the '${SPECIFIC_DB}' database!"
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo

    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Restore cancelled"
        exit 0
    fi

    # Restore single database
    echo "$(date): Restoring ${SPECIFIC_DB}..."
    if gunzip < "${BACKUP_FILE}" | mariadb -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}"; then
        echo "$(date): ✓ Database '${SPECIFIC_DB}' restored successfully"
    else
        echo "$(date): ✗ Database restore failed!" >&2
        exit 1
    fi

else
    # Restore all databases from session
    BACKUP_FILES=(${SESSION_DIR}/*.sql.gz)
    DB_COUNT=${#BACKUP_FILES[@]}

    echo "$(date): Restoring ${DB_COUNT} database(s) from session ${BACKUP_SESSION}"
    list_session_databases "${BACKUP_SESSION}"
    echo ""
    echo "WARNING: This will overwrite all these databases!"
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo

    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Restore cancelled"
        exit 0
    fi

    # Restore each database
    RESTORED_COUNT=0
    FAILED_DBS=""

    for BACKUP_FILE in "${BACKUP_FILES[@]}"; do
        DB_NAME=$(basename "${BACKUP_FILE}" .sql.gz)
        echo "$(date): Restoring ${DB_NAME}..."

        if gunzip < "${BACKUP_FILE}" | mariadb -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}"; then
            echo "$(date): ✓ ${DB_NAME} restored successfully"
            RESTORED_COUNT=$((RESTORED_COUNT + 1))
        else
            echo "$(date): ✗ Failed to restore ${DB_NAME}" >&2
            FAILED_DBS="${FAILED_DBS}${DB_NAME} "
        fi
    done

    echo "$(date): ========================================"
    echo "$(date): Restore completed: ${RESTORED_COUNT}/${DB_COUNT} database(s) restored"

    if [ -n "$FAILED_DBS" ]; then
        echo "$(date): Failed restores: ${FAILED_DBS}"
        exit 1
    fi
fi
