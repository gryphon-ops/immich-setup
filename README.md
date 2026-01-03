# Immich Setup with Tailscale

A Docker Compose setup for [Immich](https://immich.app/) — a self-hosted photo and video management application — integrated with [Tailscale](https://tailscale.com/) for secure remote access.

## Overview

This project automates the deployment of Immich with:
- **Immich Server** & **Machine Learning** microservices
- **PostgreSQL** database with vector support
- **Redis** for caching
- **Tailscale** VPN for secure remote access

All services run in isolated Docker containers and communicate through Tailscale's network.

## Prerequisites

- Docker & Docker Compose installed
- Tailscale account and auth key
- Storage locations for:
  - Media uploads (configurable via `UPLOAD_LOCATION`)
  - PostgreSQL database (uses local `./postgres` directory)

## Quick Start

### 1. Configure Environment

Copy and customize the environment template:

```bash
cp .env-template .env
```

Edit `.env` with your settings:
- `UPLOAD_LOCATION` - Path where photos/videos are stored
- `DB_PASSWORD` - PostgreSQL password (change from default)
- `IMMICH_VERSION` - Immich version to deploy (e.g., `v1.71.0` or `v2`)
- `TZ` - Your timezone

### 2. Configure Tailscale

Choose one of two authentication methods:

**Option A: Auth Key (expires)**
1. Generate an auth key from [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Update `TS_AUTHKEY` in `docker-compose.yml`:
   ```yaml
   - TS_AUTHKEY=tskey-client-YOUR_KEY_HERE
   ```
3. Note: Auth keys expire (default 90 days). You'll need to rotate them periodically.

**Option B: OAuth Client (recommended for long-term deployments)**
1. Create an OAuth client in [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth)
2. Give it Write access to Devices/Core and Keys/Auth Keys
3. Use the client ID and secret as your auth key:
   ```yaml
   - TS_AUTHKEY=tskey-oauth-YOUR_CLIENT_ID-YOUR_CLIENT_SECRET
   ```
4. Benefits: No expiration, long-term stability, better for automated deployments

### 3. Configure Tailscale Funnel (Optional)

Edit `ts-config/immich-funnel.json` to expose Immich over Tailscale Funnel:
- Replace `${TS_CERT_DOMAIN}` with your domain
- Configure proxy rules as needed

### 4. Start Services

```bash
docker compose up -d
```

Services will pull latest images and start automatically.

## File Structure

```
immich-setup/
├── docker-compose.yml           # Main Docker configuration (ignored in git)
├── docker-compose-template.yml  # Template reference
├── .env                         # Environment variables (ignored in git)
├── .env-template                # Environment template
├── update.sh                    # Automated update script
├── ts-config/
│   └── immich-funnel.json      # Tailscale Funnel config
└── postgres/                    # PostgreSQL data (ignored in git)
```

## Usage

### Update Services

Run the automated update script:

```bash
./update.sh
```

This pulls the latest images and restarts services.

### View Logs

```bash
# Tailscale service
docker logs -f tailscale-immich

# Immich server
docker logs -f immich_server

# All services
docker compose logs -f
```

### Access Immich

- **Local access**: Connect via your Tailscale IP on port 443
- **Domain access**: Use your configured domain if Funnel is enabled
- Default port in compose: `2283` (proxied through Tailscale)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `UPLOAD_LOCATION` | Media storage path | `/Volumes/Storage/Pictures/immich` |
| `DB_DATA_LOCATION` | Database storage path | `./postgres` |
| `DB_PASSWORD` | PostgreSQL password | `postgres` |
| `IMMICH_VERSION` | Release version to use | `v2` |
| `TZ` | Server timezone | `America/Detroit` |

See [Immich docs](https://immich.app/docs/install/environment-variables) for all available variables.

## Security Notes

⚠️ **Important**:
- Never commit `.env`, `docker-compose.yml`, or the `postgres/` folder to version control
- Change `DB_PASSWORD` from the default
- Rotate Tailscale auth keys regularly
- Store Tailscale auth keys securely outside version control

## Troubleshooting

### Services won't start
- Check Docker is running: `docker ps`
- Review logs: `docker compose logs`
- Verify `.env` exists and `UPLOAD_LOCATION` path is accessible

### Can't access Immich
- Confirm Tailscale is authenticated: `docker logs tailscale-immich`
- Check firewall rules in Tailscale admin console
- Verify Funnel is enabled if using domain access

### Database issues
- Ensure `DB_DATA_LOCATION` path has appropriate permissions
- Check disk space for PostgreSQL data
- Review database logs: `docker logs immich_postgres`

## References

- [Immich Documentation](https://immich.app/docs)
- [Tailscale Documentation](https://tailscale.com/kb)
- [Docker Compose Docs](https://docs.docker.com/compose/)

## License

This configuration follows Immich's licensing. See [Immich LICENSE](https://github.com/immich-app/immich/blob/main/LICENSE).
