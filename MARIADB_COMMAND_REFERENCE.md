# MariaDB Command Reference

## Important: Command Name Changes in MariaDB 12.x

**Source:** [MariaDB 10.5.2 Release Notes - mysql to mariadb binary rename](https://mariadb.com/kb/en/mariadb-1052-release-notes/)

Starting with MariaDB 10.5.2, the traditional `mysql` command names have been renamed to `mariadb` commands. The old names still exist as symlinks for compatibility, but official usage should use the new names.

## Command Mapping

| Old Command (MySQL-style) | New Command (MariaDB-style) | Purpose |
|---------------------------|----------------------------|---------|
| `mysql` | `mariadb` | Database client |
| `mysqldump` | `mariadb-dump` | Backup utility |
| `mysqladmin` | `mariadb-admin` | Administration tool |
| `mysqlcheck` | `mariadb-check` | Table maintenance |
| `mysqlimport` | `mariadb-import` | Data import tool |
| `mysqlshow` | `mariadb-show` | Database/table info |
| `mysqlbinlog` | `mariadb-binlog` | Binary log utility |

## Why This Matters

In MariaDB 12.1.2 (used in `mariadb:latest` Docker image):
- The base `mariadb:latest` image comes from the official MariaDB repository
- It includes the MariaDB server by default
- When you install `mariadb-client` package, you get the client tools
- The commands use the `mariadb-*` naming convention

**Source verification:**
```bash
# In the container, these commands exist:
$ which mariadb          # Returns: /usr/bin/mariadb
$ which mariadb-dump     # Returns: /usr/bin/mariadb-dump

# Check version
$ mariadb --version
# Output: mariadb from 12.1.2-MariaDB, client 15.2
```

## Why No Symlinks?

While older MariaDB versions created symlinks from `mysql` → `mariadb`, the Docker image we built does NOT automatically create these symlinks. This is why explicitly using `mariadb` commands is required.

## Testing

Verify commands work in the container:

```bash
# Test client connection
docker exec global-mariadb mariadb -uroot -p'PASSWORD' -e "SHOW DATABASES;"

# Check command locations
docker exec global-mariadb which mariadb        # /usr/bin/mariadb
docker exec global-mariadb which mariadb-dump   # /usr/bin/mariadb-dump
```

## References

1. **MariaDB Binary Rename Announcement**
   - https://mariadb.com/kb/en/mariadb-1052-release-notes/
   - Section: "mysql binary renamed to mariadb"

2. **mariadb-dump Documentation**
   - https://mariadb.com/kb/en/mariadb-dump/
   - All command-line options

3. **mariadb Client Documentation**
   - https://mariadb.com/kb/en/mariadb-command-line-client/
   - Connection options and usage

4. **Package Contents Verification**
   ```bash
   # From testing on actual container:
   dpkg -L mariadb-client-core | grep bin
   # Shows: /usr/bin/mariadb

   dpkg -L mariadb-client | grep dump
   # Shows: /usr/bin/mariadb-dump
   ```
