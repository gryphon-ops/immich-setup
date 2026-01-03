#!/bin/zsh
# Use to update the Immich app and Tailscale container
# Can be run on a cron: crontab -e to add a weekly schedule

# Navigate to the directory containing this script
cd "$(dirname "$0")"

docker compose pull && docker compose up -d
