#!/bin/bash

# Bash script to backup Grafana and Prometheus data

BACKUP_DIR="./backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_GRAFANA_DIR="$BACKUP_DIR/grafana_backup_$TIMESTAMP"
BACKUP_PROMETHEUS_DIR="$BACKUP_DIR/prometheus_backup_$TIMESTAMP"

# Create backup directories
mkdir -p "$BACKUP_DIR"

echo "Starting backup of Grafana and Prometheus..."
echo "Timestamp: $TIMESTAMP"

# Start services if not running
echo -e "\nChecking if services are running..."
PROMETHEUS_RUNNING=$(docker ps --filter "name=prometheus" --format "{{.Names}}" 2>/dev/null)
GRAFANA_RUNNING=$(docker ps --filter "name=grafana" --format "{{.Names}}" 2>/dev/null)

if [ -z "$PROMETHEUS_RUNNING" ]; then
    echo "Starting Prometheus..."
    docker-compose up -d prometheus
    sleep 3
fi

if [ -z "$GRAFANA_RUNNING" ]; then
    echo "Starting Grafana..."
    docker-compose up -d grafana
    sleep 3
fi

# Backup Prometheus data
echo -e "\nBacking up Prometheus data..."
mkdir -p "$BACKUP_PROMETHEUS_DIR"

docker run --rm \
    -v prometheus_data:/prometheus \
    -v "$(pwd)/$BACKUP_PROMETHEUS_DIR:/backup" \
    alpine tar czf /backup/prometheus_data.tar.gz -C / prometheus

echo "✓ Prometheus data backed up to: $BACKUP_PROMETHEUS_DIR/prometheus_data.tar.gz"

# Backup Grafana data
echo -e "\nBacking up Grafana data..."
mkdir -p "$BACKUP_GRAFANA_DIR"

docker run --rm \
    -v grafana_data:/var/lib/grafana \
    -v "$(pwd)/$BACKUP_GRAFANA_DIR:/backup" \
    alpine tar czf /backup/grafana_data.tar.gz -C /var/lib grafana

echo "✓ Grafana data backed up to: $BACKUP_GRAFANA_DIR/grafana_data.tar.gz"

# Export Grafana dashboards and datasources via API
echo -e "\nExporting Grafana dashboards via API..."
DASHBOARDS_DIR="$BACKUP_GRAFANA_DIR/dashboards"
mkdir -p "$DASHBOARDS_DIR"

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin"

# Get all dashboards
DASHBOARDS=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" "$GRAFANA_URL/api/search" 2>/dev/null)

if command -v jq &> /dev/null; then
    while IFS= read -r dashboard; do
        DASH_UID=$(echo "$dashboard" | jq -r '.uid')
        DASH_TITLE=$(echo "$dashboard" | jq -r '.title')
        DASH_TYPE=$(echo "$dashboard" | jq -r '.type')
        
        if [ "$DASH_TYPE" = "dash-db" ]; then
            curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
                "$GRAFANA_URL/api/dashboards/uid/$DASH_UID" \
                > "$DASHBOARDS_DIR/${DASH_TITLE}_${DASH_UID}.json"
            echo "  ✓ Exported dashboard: $DASH_TITLE"
        fi
    done < <(echo "$DASHBOARDS" | jq -c '.[]')
else
    echo "  ⚠ jq not installed, skipping dashboard export"
fi

# Create summary file
SUMMARY_FILE="$BACKUP_DIR/backup_summary_$TIMESTAMP.txt"
cat > "$SUMMARY_FILE" << EOF
Backup Summary - $TIMESTAMP
================================

Grafana Backup:
- Location: $BACKUP_GRAFANA_DIR
- Data Archive: grafana_data.tar.gz
- Dashboards: $DASHBOARDS_DIR

Prometheus Backup:
- Location: $BACKUP_PROMETHEUS_DIR
- Data Archive: prometheus_data.tar.gz

Restore Instructions:
====================

For Prometheus:
  docker run --rm -v prometheus_data:/prometheus -v <path-to-backup>:/backup alpine tar xzf /backup/prometheus_data.tar.gz -C /

For Grafana:
  docker run --rm -v grafana_data:/var/lib/grafana -v <path-to-backup>:/backup alpine tar xzf /backup/grafana_data.tar.gz -C /var/lib

EOF

echo -e "\n✓ Backup completed successfully!"
echo "Summary saved to: $SUMMARY_FILE"
echo -e "\nBackup location: $(pwd)/$BACKUP_DIR"
