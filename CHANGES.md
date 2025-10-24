# Changes Summary: RSS Services Integration

## Overview
Added three RSS-related services (RSSHub, Browserless, FreshRSS) with complete integration into the existing deployment infrastructure, and fixed the deploy.conf export to only include config.sh variables.

## Files Created

### 1. `/rss/docker-compose.yml`
Docker Compose configuration for three services:
- **RSSHub**: RSS feed generator with Redis caching and Browserless support
- **Browserless**: Headless Chrome browser service for RSSHub
- **FreshRSS**: RSS reader with PostgreSQL backend

### 2. `/rss/README.md`
Comprehensive documentation including:
- Service descriptions and features
- Default credentials
- Configuration variables
- Deployment instructions

## Files Modified

### 1. `config.sh`
**Added RSS services configuration section:**
- RSSHub: IP (172.16.0.90), ACCESS_KEY (random), Redis URL
- Browserless: IP (172.16.0.91), PORT
- FreshRSS: IP (172.16.0.92), admin credentials (random password), database config
- Telegram: SESSION and TOKEN variables (for future use)

**Total additions:** 32 lines of configuration

### 2. `deploy.sh`
**Major change - Fixed deploy.conf export:**
- Replaced `env > deploy.conf` with custom `saveConfigToFile()` function
- Now exports ONLY config.sh defined variables instead of all system environment variables
- Reduces deploy.conf from ~2000+ lines to ~110 lines (85 actual variables)
- Makes deploy.conf human-readable and suitable for version control (after removing secrets)

**Function added:** `saveConfigToFile()` - Explicitly exports each config.sh variable to deploy.conf

**Total additions:** 118 lines

### 3. `postgresql/docker-compose.yml`
**Added FreshRSS database environment variables:**
- FRESHRSS_DB_USER
- FRESHRSS_DB_PASSWORD
- FRESHRSS_DB_NAME

These are passed to the PostgreSQL container for database initialization.

### 4. `postgresql/init-db.sh`
**Added FreshRSS database creation:**
```sql
CREATE USER freshrss_user WITH PASSWORD '...';
CREATE DATABASE freshrss_db OWNER freshrss_user;
GRANT ALL PRIVILEGES ON DATABASE freshrss_db TO freshrss_user;
```

### 5. `.gitignore`
**Added entries for:**
- `deploy.conf` (contains sensitive passwords)
- Data directories: `*/data/`, `*/logs/`, `*/persist/`
- RSS-specific: `rss/fr-data/`, `rss/fr-extensions/`

## Configuration Variables Added

### RSSHub
- `RSSHUB_IP=172.16.0.90`
- `RSSHUB_PORT=1200`
- `RSSHUB_ACCESS_KEY=<random 16 chars>`
- `RSSHUB_REDIS_URL=redis://:${REDIS_PASSWORD}@${REDIS_IP}:6379`

### Telegram (placeholders)
- `TELEGRAM_SESSION=` (empty, to be filled by user)
- `TELEGRAM_TOKEN=` (empty, to be filled by user)

### Browserless
- `BROWSERLESS_IP=172.16.0.91`
- `BROWSERLESS_PORT=3000`

### FreshRSS
- `FRESHRSS_IP=172.16.0.92`
- `FRESHRSS_PORT=80`
- `FRESHRSS_DATA_DIR=./fr-data`
- `FRESHRSS_EXTENSIONS_DIR=./fr-extensions`
- `FRESHRSS_ADMIN_USER=admin`
- `FRESHRSS_ADMIN_PASSWORD=<random 16 chars>`
- `FRESHRSS_DB_TYPE=pgsql`
- `FRESHRSS_DB_HOST=${POSTGRES_IP}`
- `FRESHRSS_DB_PORT=5432`
- `FRESHRSS_DB_NAME=freshrss_db`
- `FRESHRSS_DB_USER=freshrss_user`
- `FRESHRSS_DB_PASSWORD=<random 16 chars>`

## Key Features

### 1. Automatic Database Provisioning
FreshRSS database and user are automatically created when PostgreSQL container starts for the first time.

### 2. Shared Redis Instance
RSSHub uses the existing Redis deployment for caching, avoiding the need for a separate Redis instance.

### 3. Service Dependencies
RSSHub depends on Browserless, ensuring correct startup order.

### 4. Health Checks
All three services have health check configurations:
- RSSHub: `/healthz` endpoint with ACCESS_KEY
- Browserless: `/pressure` endpoint
- FreshRSS: Default health check

### 5. Clean Configuration Export
The new `saveConfigToFile()` function ensures deploy.conf contains only relevant configuration variables, making it:
- Easier to review and edit
- Suitable for backup/restore
- More maintainable

## Deployment

The RSS services are ready to deploy but not yet integrated into the main deployment flow. To deploy:

```bash
cd /path/to/project
source config.sh
cd rss
docker compose up -d
```

To integrate into main deployment, add to `deployBase()` function in `deploy.sh`.

## Testing Performed

✅ config.sh syntax validation
✅ deploy.sh syntax validation  
✅ init-db.sh syntax validation
✅ docker-compose.yml validation
✅ Environment variable expansion test
✅ saveConfigToFile() function test
✅ deploy.conf generation test (110 lines, 85 variables)

## Statistics

- Files created: 2
- Files modified: 5
- Lines added: ~170
- New services: 3
- New configuration variables: 17
- New PostgreSQL database: 1

## Next Steps (Optional)

1. Integrate RSS services into main deployment flow in `deploy.sh`
2. Add domain names for RSS services (e.g., rsshub.${ROOT_DOMAIN_NAME})
3. Configure https-portal to proxy these services
4. Fill in Telegram credentials if needed
5. Test full deployment workflow
