@echo off
REM Database restore script for Windows

if "%~1"=="" (
    echo Usage:
    echo   db-restore.bat ^<backup_session^>                  - Restore all databases from a session
    echo   db-restore.bat ^<backup_session^> ^<database_name^>  - Restore specific database
    echo.
    echo Example: db-restore.bat 20260108_020000
    echo Example: db-restore.bat 20260108_020000 my_database
    echo.
    echo Listing available backup sessions:
    docker compose exec db-backup /usr/local/bin/restore.sh
    exit /b 1
)

if "%~2"=="" (
    echo Restoring all databases from session: %1
    docker compose exec -it db-backup /usr/local/bin/restore.sh %1
) else (
    echo Restoring database %2 from session: %1
    docker compose exec -it db-backup /usr/local/bin/restore.sh %1 %2
)
