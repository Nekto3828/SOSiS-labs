#!/usr/bin/env pwsh

# PowerShell script to backup Grafana and Prometheus data

$BackupDir = "./backup"
$Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$BackupGrafanaDir = "$BackupDir/grafana_backup_$Timestamp"
$BackupPrometheusDir = "$BackupDir/prometheus_backup_$Timestamp"

# Create backup directories
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

Write-Host "Starting backup of Grafana and Prometheus..." -ForegroundColor Green
Write-Host "Timestamp: $Timestamp" -ForegroundColor Cyan

# Start services if not running
Write-Host "`nChecking if services are running..." -ForegroundColor Yellow
$PrometheusRunning = docker ps --filter "name=prometheus" --format "{{.Names}}" 2>$null
$GrafanaRunning = docker ps --filter "name=grafana" --format "{{.Names}}" 2>$null

if (-not $PrometheusRunning) {
    Write-Host "Starting Prometheus..." -ForegroundColor Yellow
    docker-compose up -d prometheus
    Start-Sleep -Seconds 3
}

if (-not $GrafanaRunning) {
    Write-Host "Starting Grafana..." -ForegroundColor Yellow
    docker-compose up -d grafana
    Start-Sleep -Seconds 3
}

# Backup Prometheus data
Write-Host "`nBacking up Prometheus data..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupPrometheusDir -Force | Out-Null

# Copy Prometheus volume data
docker run --rm `
    -v prometheus_data:/prometheus `
    -v "$(Resolve-Path $BackupPrometheusDir):/backup" `
    alpine tar czf /backup/prometheus_data.tar.gz -C / prometheus

Write-Host "✓ Prometheus data backed up to: $BackupPrometheusDir/prometheus_data.tar.gz" -ForegroundColor Green

# Backup Grafana data
Write-Host "`nBacking up Grafana data..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupGrafanaDir -Force | Out-Null

# Copy Grafana volume data
docker run --rm `
    -v grafana_data:/var/lib/grafana `
    -v "$(Resolve-Path $BackupGrafanaDir):/backup" `
    alpine tar czf /backup/grafana_data.tar.gz -C /var/lib grafana

Write-Host "✓ Grafana data backed up to: $BackupGrafanaDir/grafana_data.tar.gz" -ForegroundColor Green

# Export Grafana dashboards and datasources via API
Write-Host "`nExporting Grafana dashboards via API..." -ForegroundColor Yellow
$GrafanaUrl = "http://localhost:3000"
$GrafanaUser = "admin"
$GrafanaPassword = "admin"
$Auth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$GrafanaUser`:$GrafanaPassword"))

# Get all dashboards
$DashboardsDir = "$BackupGrafanaDir/dashboards"
New-Item -ItemType Directory -Path $DashboardsDir -Force | Out-Null

try {
    $Dashboards = Invoke-RestMethod -Uri "$GrafanaUrl/api/search" `
        -Headers @{"Authorization" = "Basic $Auth"} `
        -Method Get

    foreach ($Dashboard in $Dashboards) {
        if ($Dashboard.type -eq "dash-db") {
            $DashUid = $Dashboard.uid
            $DashboardJson = Invoke-RestMethod -Uri "$GrafanaUrl/api/dashboards/uid/$DashUid" `
                -Headers @{"Authorization" = "Basic $Auth"} `
                -Method Get
            
            $DashboardJson | ConvertTo-Json -Depth 100 | Out-File "$DashboardsDir/$($Dashboard.title)_$DashUid.json"
            Write-Host "  ✓ Exported dashboard: $($Dashboard.title)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "  ⚠ Could not export dashboards via API: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create summary file
$SummaryFile = "$BackupDir/backup_summary_$Timestamp.txt"
$Summary = @"
Backup Summary - $Timestamp
================================

Grafana Backup:
- Location: $BackupGrafanaDir
- Data Archive: grafana_data.tar.gz
- Dashboards: $DashboardsDir

Prometheus Backup:
- Location: $BackupPrometheusDir
- Data Archive: prometheus_data.tar.gz

Restore Instructions:
====================

For Prometheus:
  docker run --rm -v prometheus_data:/prometheus -v <path-to-backup>:/backup alpine tar xzf /backup/prometheus_data.tar.gz -C /

For Grafana:
  docker run --rm -v grafana_data:/var/lib/grafana -v <path-to-backup>:/backup alpine tar xzf /backup/grafana_data.tar.gz -C /var/lib

"@

$Summary | Out-File $SummaryFile

Write-Host "`n✓ Backup completed successfully!" -ForegroundColor Green
Write-Host "Summary saved to: $SummaryFile" -ForegroundColor Cyan
Write-Host "`nBackup location: $(Resolve-Path $BackupDir)" -ForegroundColor Cyan
