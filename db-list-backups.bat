@echo off
REM List all database backups

if "%~1"=="" (
    echo Available backup sessions:
    echo.
    docker compose exec db-backup ls -lt /backups
    echo.
    echo To see databases in a specific session, run:
    echo   db-list-backups.bat ^<session_name^>
    echo.
    echo Example: db-list-backups.bat 20260108_020000
) else (
    echo Databases in backup session %1:
    echo.
    docker compose exec db-backup ls -lh /backups/%1
)
