#!/bin/bash

echo "[$(date)]: Starting PostgreSQL backup"

# Variables
REMOTE_NAME="gdrive"
REMOTE_FOLDER="rclone-postgresql-backup"
REMOTE_PATH="${REMOTE_NAME}:/${REMOTE_FOLDER}/"

DB_HOST="localhost"
DB_USER="postgres"
DB_NAME="mydb"

TIMESTAMP=$(date +%s%3N)
BACKUP_FILE="${DB_NAME}-${TIMESTAMP}.dump.gz"
BACKUP_DIR="/tmp/postgresql-backup"

MAX_FILES=9
FILES_PATTERN="^${DB_NAME}-[0-9]+\.dump\.gz$"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Create PostgreSQL dump, compress it, and upload to Google Drive
echo "[$(date)]: Creating backup and uploading to Google Drive..."
PGPASSWORD='YOUR_DB_PASSWORD' pg_dump -h "$DB_HOST" -U "$DB_USER" -F c -d "$DB_NAME" | gzip > "$BACKUP_DIR/$BACKUP_FILE"

if rclone copy "$BACKUP_DIR/$BACKUP_FILE" "$REMOTE_PATH"; then
    echo "[$(date)]: Backup uploaded successfully. Cleaning up local file..."
    rm -f "$BACKUP_DIR/$BACKUP_FILE"
else
    echo "[$(date)]: Backup upload failed. Local file retained: $BACKUP_DIR/$BACKUP_FILE"
fi

echo "[$(date)]: PostgreSQL backup completed"

# ====================================================================

echo "[$(date)]: Starting PostgreSQL Google Drive cleanup"

# Get the list of matching files from the remote path, sorted by timestamp in descending order
files=$(rclone lsf --files-only "$REMOTE_PATH" | grep -E "$FILES_PATTERN" | sort -t'-' -k2 -n -r)

# Count the total number of matching files
file_count=$(echo "$files" | wc -l)

# Check if the number of files exceeds the limit
if [ "$file_count" -gt "$MAX_FILES" ]; then

    # Calculate how many files need to be deleted
    files_to_delete=$(echo "$files" | tail -n +$((MAX_FILES + 1)))

    # Delete the oldest files from Google Drive
    echo "$files_to_delete" | while read -r file; do
        echo "[$(date)]: Deleting $REMOTE_PATH$file"
        rclone delete "$REMOTE_PATH$file"
    done
else
    echo "[$(date)]: No files to delete. Total files ($file_count) are within the limit ($MAX_FILES)"
fi

echo "[$(date)]: Clearing the trash on Google Drive..."
rclone cleanup ${REMOTE_NAME}:
echo "[$(date)]: Trash cleared"

echo "[$(date)]: PostgreSQL Google Drive cleanup completed"

echo "[$(date)]: ===================================================================="
