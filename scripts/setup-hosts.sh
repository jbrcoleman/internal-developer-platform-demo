#!/bin/bash
set -e

# This script adds local domain entries to /etc/hosts
# Run with: sudo ./scripts/setup-hosts.sh

HOSTS_FILE="/etc/hosts"
DOMAINS="argocd.local rollouts.local prometheus.local grafana.local demo-app-1.local"

echo "Adding local domains to $HOSTS_FILE..."

for domain in $DOMAINS; do
    if grep -q "$domain" "$HOSTS_FILE"; then
        echo "  $domain already exists, skipping"
    else
        echo "127.0.0.1 $domain" >> "$HOSTS_FILE"
        echo "  Added $domain"
    fi
done

echo ""
echo "Current local entries:"
grep "\.local" "$HOSTS_FILE" || echo "  (none found)"
echo ""
echo "Done!"
