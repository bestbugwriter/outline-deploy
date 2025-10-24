# RSS Services Quick Start Guide

## Quick Deploy

```bash
# 1. Source configuration
cd /path/to/project
source config.sh

# 2. Deploy RSS services
cd rss
docker compose up -d

# 3. Check service status
docker compose ps

# 4. View logs
docker compose logs -f
```

## Access Information

After deployment, check `deploy.conf` for credentials:

```bash
# FreshRSS Admin
grep FRESHRSS_ADMIN deploy.conf

# RSSHub Access Key
grep RSSHUB_ACCESS_KEY deploy.conf
```

## Service URLs

- **RSSHub**: `http://<RSSHUB_IP>:1200`
- **FreshRSS**: `http://<FRESHRSS_IP>`
- **Browserless**: `http://<BROWSERLESS_IP>:3000` (internal service)

## Default Credentials

### FreshRSS
- URL: `http://172.16.0.92`
- Username: `admin`
- Password: See `FRESHRSS_ADMIN_PASSWORD` in `deploy.conf`

### RSSHub
- URL: `http://172.16.0.90:1200`
- Access Key: See `RSSHUB_ACCESS_KEY` in `deploy.conf`
- Health Check: `http://172.16.0.90:1200/healthz?key=<ACCESS_KEY>`

## Adding RSS Feeds in FreshRSS

1. Log in to FreshRSS web interface
2. Click "Subscribe to a new feed"
3. Enter RSSHub feed URL, for example:
   - GitHub Releases: `http://172.16.0.90:1200/github/issue/vuejs/core?key=<ACCESS_KEY>`
   - Reddit: `http://172.16.0.90:1200/reddit/user/username?key=<ACCESS_KEY>`

Note: Replace `<ACCESS_KEY>` with the actual key from `deploy.conf`

## Telegram Configuration (Optional)

If you need Telegram support for RSSHub:

1. Get your Telegram token from [@BotFather](https://t.me/botfather)
2. Get your session string
3. Edit `deploy.conf`:
   ```bash
   TELEGRAM_SESSION=your_session_string_here
   TELEGRAM_TOKEN=your_bot_token_here
   ```
4. Restart RSS services:
   ```bash
   cd rss
   docker compose restart rsshub
   ```

## Troubleshooting

### FreshRSS can't connect to database
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Check FreshRSS logs
cd rss
docker compose logs freshrss
```

### RSSHub can't connect to Redis
```bash
# Check Redis is running
docker ps | grep redis

# Check Redis URL in config
echo $RSSHUB_REDIS_URL
```

### Browserless not working
```bash
# Check container status
cd rss
docker compose ps browserless

# Check logs
docker compose logs browserless
```

## Data Persistence

Data is stored in:
- `./fr-data`: FreshRSS articles and configuration
- `./fr-extensions`: FreshRSS plugins

These directories are created automatically on first run.

## Backup

To backup your RSS setup:
```bash
cd rss
tar czf rss-backup-$(date +%Y%m%d).tar.gz fr-data fr-extensions
```

## Restore

To restore from backup:
```bash
cd rss
tar xzf rss-backup-YYYYMMDD.tar.gz
docker compose restart freshrss
```
