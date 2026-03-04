# Grafana & Prometheus Backup Restore Guide

## Backup Details

**Backup Timestamp:** 2026-03-05_00-16-01

### Files Backed Up:
- **prometheus_data_2026-03-05_00-16-01.tar.gz** (38.29 KB)
  - Contains all Prometheus TSDB data and metrics
  
- **grafana_data_2026-03-05_00-16-01.tar.gz** (43,238.58 KB)
  - Contains all Grafana dashboards, datasources, users, and configurations

---

## Restoration Instructions

### Option 1: Using Docker Volumes (Recommended)

#### Prerequisites:
- Docker and Docker Compose installed
- Services stopped or volumes not in use

#### For Prometheus:

```bash
# Stop Prometheus container
docker-compose down prometheus

# Remove the volume (optional - to start fresh)
docker volume rm prometheus_data

# Extract backup into volume
docker run --rm \
  -v prometheus_data:/prometheus \
  -v /path/to/backup:/backup \
  alpine tar xzf /backup/prometheus_data_2026-03-05_00-16-01.tar.gz -C / prometheus

# Restart Prometheus
docker-compose up -d prometheus
```

#### For Grafana:

```bash
# Stop Grafana container
docker-compose down grafana

# Remove the volume (optional - to start fresh)
docker volume rm grafana_data

# Extract backup into volume
docker run --rm \
  -v grafana_data:/var/lib/grafana \
  -v /path/to/backup:/backup \
  alpine tar xzf /backup/grafana_data_2026-03-05_00-16-01.tar.gz -C /var/lib grafana

# Restart Grafana
docker-compose up -d grafana
```

### Option 2: Direct Container Restore

If you prefer to extract directly into running containers:

```bash
# For Prometheus
docker exec prometheus tar xzf - -C /prometheus < prometheus_data_2026-03-05_00-16-01.tar.gz

# For Grafana
docker exec grafana tar xzf - -C /var/lib/grafana < grafana_data_2026-03-05_00-16-01.tar.gz

# Restart to ensure consistency
docker-compose restart prometheus grafana
```

### Option 3: Manual File Copy

```bash
# Extract archives locally first
tar xzf prometheus_data_2026-03-05_00-16-01.tar.gz
tar xzf grafana_data_2026-03-05_00-16-01.tar.gz

# Copy to volume mount points
docker cp prometheus/. prometheus:/prometheus/
docker cp grafana/. grafana:/var/lib/grafana/

# Restart containers
docker-compose restart
```

---

## Verification After Restore

### Check Prometheus:
```bash
# Access Prometheus UI
http://localhost:9090

# Verify metrics are loaded
curl http://localhost:9090/api/v1/targets
```

### Check Grafana:
```bash
# Access Grafana UI
http://localhost:3000

# Login with credentials (default: admin/admin unless changed)
# Verify dashboards are loaded
# Check Data Sources configuration
```

---

## Troubleshooting

### Prometheus Data Not Appearing

1. **Check volume exists:**
   ```bash
   docker volume ls | grep prometheus
   ```

2. **Check container logs:**
   ```bash
   docker logs prometheus
   ```

3. **Verify mount point:**
   ```bash
   docker inspect prometheus | grep -A 20 Mounts
   ```

### Grafana Dashboards Missing

1. **Check Grafana logs:**
   ```bash
   docker logs grafana
   ```

2. **Verify permissions:**
   ```bash
   docker exec grafana ls -la /var/lib/grafana/
   ```

3. **Access Grafana API to check datasources:**
   ```bash
   curl -u admin:admin http://localhost:3000/api/datasources
   ```

### Permission Issues

If you encounter permission denied errors:

```bash
# Run Grafana with same user ID as backup
docker-compose down
docker volume rm grafana_data
# Then restore with explicit permissions
docker run --rm \
  -v grafana_data:/var/lib/grafana \
  -v /path/to/backup:/backup \
  alpine sh -c "tar xzf /backup/grafana_data_2026-03-05_00-16-01.tar.gz -C /var/lib && chown -R 472:472 /var/lib/grafana"
```

---

## Backup Schedule

For regular backups, use the provided scripts:

**Windows (PowerShell):**
```powershell
./backup_grafana_prometheus.ps1
```

**Linux/macOS (Bash):**
```bash
./backup_grafana_prometheus.sh
```

To automate, add to cron (Linux/macOS):
```bash
# Daily backup at 2 AM
0 2 * * * /path/to/backup_grafana_prometheus.sh
```

Or Task Scheduler (Windows):
```
Create scheduled task running: C:\Windows\System32\powershell.exe -ExecutionPolicy Bypass -File C:\path\to\backup_grafana_prometheus.ps1
```

---

## Best Practices

1. **Backup Frequency:** Weekly or daily depending on your monitoring needs
2. **Test Restores:** Periodically test restore procedures on non-production environments
3. **Secure Backups:** Store backups in a secure location with proper access controls
4. **Document Changes:** Keep notes of configuration changes between backups
5. **Retention Policy:** Keep at least 3-4 weeks of daily backups
6. **Off-site Storage:** Consider backing up to cloud storage (S3, Google Cloud, Azure)

---

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Backup and Restore](https://grafana.com/docs/grafana/latest/administration/back-up-grafana/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
