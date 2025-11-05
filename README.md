# Global Database Stack

A Docker Compose stack for running a shared MariaDB database with phpMyAdmin interface.

## Features

- MariaDB latest with optimized configuration
- phpMyAdmin web interface
- Configurable via environment variables
- Persistent data storage
- External network support for multi-stack connectivity

## Prerequisites

- Docker
- Docker Compose
- An external Docker network named `wp-network` (or configure to create internally)

## Setup Instructions

### 1. Create the External Network (if needed)

If you want to use an external network to connect multiple Docker Compose stacks:

```bash
docker network create wp-network
```

### 2. Configure Environment Variables

Copy the example environment file and customize it:

```bash
cp .env.example .env
```

Edit `.env` and update the following values:

#### Required Settings
- `MYSQL_ROOT_PASSWORD`: Set a strong password for MariaDB root user
- `PMA_CONTROLPASS`: Set a strong password for phpMyAdmin control user

#### Optional Settings
You can customize these based on your needs:
- `MARIADB_PORT`: Host port for MariaDB (default: 3306)
- `PHPMYADMIN_PORT`: Host port for phpMyAdmin (default: 8080)
- `INNODB_BUFFER_POOL_SIZE`: Memory allocation for InnoDB (default: 128M)
- `MAX_CONNECTIONS`: Maximum database connections (default: 50)
- `UPLOAD_LIMIT`: phpMyAdmin upload limit (default: 1024M)
- `MEMORY_LIMIT`: phpMyAdmin memory limit (default: 5125M)
- `MAX_EXECUTION_TIME`: phpMyAdmin execution time limit (default: 600)
- `NETWORK_EXTERNAL`: Set to `false` if you want Docker Compose to create the network

### 3. Start the Stack

```bash
docker-compose up -d
```

### 4. Verify the Services

Check that all services are running:

```bash
docker-compose ps
```

## Accessing Services

- **MariaDB**: `localhost:3306` (or custom port from `.env`)
- **phpMyAdmin**: `http://localhost:8080` (or custom port from `.env`)

### phpMyAdmin Login

- **Username**: `root`
- **Password**: Your `MYSQL_ROOT_PASSWORD` from `.env`

## Managing the Stack

### View logs
```bash
docker-compose logs -f
```

### Stop the stack
```bash
docker-compose down
```

### Stop and remove volumes (WARNING: This deletes all data)
```bash
docker-compose down -v
```

### Restart the stack
```bash
docker-compose restart
```

## Database Configuration

The MariaDB instance is configured with:
- UTF-8 MB4 character set and collation
- MySQL native password authentication
- Optimized InnoDB buffer pool
- Configurable connection limits

## Volumes

- `mariadb_data`: Persistent storage for MariaDB data
- `phpmyadmin_data`: Temporary storage for phpMyAdmin

## Security Notes

- Always use strong passwords in your `.env` file
- Never commit your `.env` file to version control
- Consider restricting port exposure if not needed externally
- Use firewall rules to limit access to database ports

## Troubleshooting

### Cannot connect to database
- Ensure the MariaDB container is running: `docker-compose ps`
- Check logs: `docker-compose logs global-mariadb`
- Verify the `.env` file has correct credentials

### phpMyAdmin shows errors
- Check that MariaDB is fully started before phpMyAdmin
- Restart the stack: `docker-compose restart`
- Verify environment variables in `.env`

### Network errors
- Ensure the `wp-network` exists: `docker network ls`
- Create it if missing: `docker network create wp-network`
- Or set `NETWORK_EXTERNAL=false` in `.env` to create it automatically

## License

This project is provided as-is for personal and commercial use.
