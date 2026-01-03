# Immich Setup with Tailscale

A Docker Compose setup for [Immich](https://immich.app/) — a self-hosted photo and video management application — integrated with [Tailscale](https://tailscale.com/) for secure remote access.

## Disclaimer

I've only tested this on a mac mini, other systems might run into other error. I made this doc with AI following all my troubleshooting attempts. Hopefully it's useful, but it might have errors. Feel free to contribute updates and fixes if you find any :)

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

## Post-Installation Configuration

After services start, several critical configuration steps are required for a fully operational zero open ports deployment.

### 1. Tailscale OAuth & Tag Configuration

If using an OAuth client, define the tag in your Tailscale Access Control List (ACL):

1. Open **Tailscale Admin Console** > **Access Control**
2. Add `tagOwners` for your tag:
   ```json
   "tagOwners": {
       "tag:container": ["your-admin-email@example.com"]
   }
   ```
3. Go to **Settings** > **OAuth Clients** > **Generate OAuth Client**
4. Configure:
   - Scope: `Devices: Write`
   - Tag: `tag:container` (or your chosen tag)
5. Copy the **Client Secret** and use it as `TS_AUTHKEY` in your docker-compose.yml

### 2. Disable Key Expiry

By default, Tailscale nodes expire after 180 days. For a persistent server, disable expiry:

1. Go to **Machines** tab in Tailscale Admin Console
2. Locate your `immich` machine
3. Click the three dots `...` > **Disable Key Expiry**
   - *Note: OAuth clients often have this disabled automatically, but verify to be sure*

### 3. Configure Immich Trusted Proxies

Tailscale Funnel acts as a reverse proxy, so Immich needs to trust headers for correct HTTPS handling:

1. Log into Immich as an **Admin**
2. Go to **Administration** > **Settings** > **Server Settings**
3. Find **Proxy Settings**
4. In **Trusted Proxies**, add the Docker internal IP range: `172.18.0.0/16`
   - Or add the specific Tailscale container IP
5. Set **External Domain** to `https://immich.your-tailnet.ts.net`

### 4. Verify Tailscale Funnel Status

If the page loads but gets stuck, check Funnel status:

```bash
docker exec -it tailscale-immich tailscale funnel status
```

**Important**: Immich must be served at the root `/` of the hostname, not a sub-path. Tailscale Funnel automatically translates port 443 to internal port 2283.

### 5. Mobile App Configuration

To use the Immich mobile app:

1. **Server URL**: Enter `https://immich.your-tailnet.ts.net`
   - Do NOT include a port number; Funnel handles the translation automatically
2. **Tailscale on Phone**: Not required if Funnel is enabled, as the app connects via public internet
3. If Funnel is disabled, enable Tailscale on your phone and connect to your Tailnet first

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

### Tailscale Container Issues

Run this command to filter errors:

```bash
docker logs tailscale-immich 2>&1 | grep -iE "error|warn|fatal|forbidden"
```

**Common errors**:
- `403 Forbidden`: OAuth client missing `Devices: Write` scope or tag not assigned correctly
- `Getting OS base config is not supported`: Add `TS_USERSPACE=true` to `docker-compose.yml` environment variables

### Can't access Immich
- Confirm Tailscale authentication: `docker logs tailscale-immich`
- Check Funnel status: `docker exec -it tailscale-immich tailscale funnel status`
- Verify firewall rules in Tailscale admin console
- Ensure Trusted Proxies are configured in Immich settings
- Check that External Domain is set to your Tailscale domain

### Page loads but gets stuck (blank/loading)
- Verify Funnel is enabled and routing correctly
- Check browser console for failed requests (F12 > Console)
- Ensure **no sub-path** is being used; Immich must be at `/`
- Verify Trusted Proxies include the Docker network range `172.18.0.0/16`

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
