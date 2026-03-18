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

## Database Access

```bash
# Access MySQL prompt
docker exec -it global-mariadb mysql -uroot -p

# Quick query without prompt
docker exec global-mariadb mysql -uroot -p'YOUR_PASSWORD' -e "SHOW DATABASES;"
```

## Monitoring

```bash
# View MariaDB logs (live)
docker compose logs -f global-mariadb

# View last 50 lines
docker compose logs --tail=50 global-mariadb
```

## Troubleshooting

```bash
# Restart a service
docker compose restart global-mariadb

# Verify .env passwords match
cat .env | grep PASSWORD
```
