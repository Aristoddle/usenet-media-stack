# Backup Strategies

Comprehensive backup and disaster recovery strategies for your Usenet Media Stack, covering configuration protection, data recovery, and business continuity planning for both home and professional deployments.

## Backup Philosophy

### Configuration vs. Data Backup

**Smart Backup Strategy:**
- ✅ **Configuration backup** - Service settings, automation rules, API keys (~5-50MB)
- ❌ **Media backup** - Movies, TV shows, music (would be 10-100TB+)

**Rationale:**
- **Media is replaceable** - Can be re-downloaded from original sources
- **Configuration is irreplaceable** - Custom quality profiles, automation rules, years of tuning
- **Cost-effective** - Store TB of configurations vs PB of media
- **Fast recovery** - Restore services in minutes, not days

### Backup Categories

```
Backup Architecture:
├── Critical (Real-time)
│   ├── Service configurations
│   ├── API keys and credentials
│   ├── Database states
│   └── Custom automation scripts
├── Important (Daily)
│   ├── Quality profiles and custom formats
│   ├── Download history and statistics
│   ├── User preferences and settings
│   └── Plugin configurations
├── Convenience (Weekly)
│   ├── Log files and metrics
│   ├── Cache and temporary files
│   └── Generated thumbnails
└── Reference (Monthly)
    ├── System configuration snapshots
    ├── Performance baselines
    └── Documentation updates
```

## Configuration Backup System

### Built-in Backup Features

#### Automatic Configuration Backup

```bash
# Enable automatic daily backups
./usenet backup schedule --daily --time 03:00 --retain 30

# Create immediate backup
./usenet backup create --name "pre-major-change-$(date +%Y%m%d)"

# Backup with compression and metadata
./usenet backup create --compress --include-metadata
```

#### Backup Content Analysis

```bash
# View what's included in backups
./usenet backup show latest --list-contents

# Expected backup contents:
# ✓ .env (credentials and configuration)
# ✓ docker-compose.yml files (3-5 files)
# ✓ config/ directory (19 service configurations)
# ✓ scripts/ directory (management tools)
# ✓ Generated files (storage.conf, hardware_profile.conf)
# ✗ Media files (excluded by design)
# ✗ Download cache (excluded for size)
# ✗ Logs (optional inclusion)
```

#### Backup Metadata and Verification

```bash
# View backup metadata
./usenet backup show backup-20240115.tar.gz --metadata
```

**Backup Metadata Example:**
```json
{
  "backup": {
    "version": "2.0",
    "created": "2024-01-15T14:30:22.123Z",
    "name": "usenet-stack-2024-01-15_143022",
    "size": {
      "compressed": 4426752,
      "uncompressed": 19612160,
      "compression_ratio": 0.77
    }
  },
  "system": {
    "os": "Ubuntu 22.04.3 LTS",
    "cpu": "AMD Ryzen 7 7840HS",
    "memory": "30GB",
    "gpu": "AMD Radeon 780M"
  },
  "services": {
    "total": 19,
    "running": 19,
    "configurations": [
      {"name": "sonarr", "version": "3.0.10", "config_size": "2.1MB"},
      {"name": "radarr", "version": "4.7.5", "config_size": "1.8MB"}
    ]
  },
  "storage": {
    "drives": 2,
    "total_capacity": "12TB",
    "pool_configuration": "hot_swappable_jbod"
  }
}
```

### Advanced Backup Configuration

#### Selective Backup Strategies

```bash
# Configuration-only backup (default, recommended)
./usenet backup create --config-only

# Include service metadata and history
./usenet backup create --include-metadata --include-history

# Include logs for troubleshooting
./usenet backup create --include-logs --max-log-age 7d

# Full backup including download cache (WARNING: Large)
./usenet backup create --include-downloads --max-size 50G
```

#### Backup Exclusion Patterns

```bash
# Create custom backup exclusion file
cat > ./config/backup_exclusions.txt << 'EOF'
# Exclude large media files
**/*.mkv
**/*.mp4
**/*.avi
**/*.m2ts

# Exclude cache directories
**/cache/
**/Cache/
**/thumbnails/

# Exclude temporary files
**/tmp/
**/temp/
**/*.tmp
**/*.log

# Exclude incomplete downloads
**/incomplete/
**/_UNPACK_*/
**/_FAILED_*/
EOF

# Use exclusion file
./usenet backup create --exclude-file ./config/backup_exclusions.txt
```

## Disaster Recovery Planning

### Recovery Scenarios

#### Scenario 1: Service Configuration Corruption

**Problem:** Single service configuration corrupted (e.g., Sonarr database corruption)

**Recovery:**
```bash
# Stop affected service
./usenet services stop sonarr

# Backup current state for analysis
./usenet backup create --name "corrupted-sonarr-$(date +%Y%m%d%H%M)"

# Restore from latest good backup
./usenet backup restore latest --services sonarr

# Verify restoration
./usenet services start sonarr
./usenet services health sonarr --detailed
```

#### Scenario 2: Complete System Failure

**Problem:** Hardware failure, OS corruption, or complete system loss

**Recovery:**
```bash
# On new system, after basic OS installation:

# 1. Install prerequisites
./scripts/install_prerequisites.sh

# 2. Clone repository
git clone https://github.com/user/usenet-media-stack.git
cd usenet-media-stack

# 3. Restore from backup
./usenet backup restore /path/to/backup.tar.gz --full-restore

# 4. Verify and start services
./usenet validate --fix
./usenet deploy --from-backup
```

#### Scenario 3: Data Center / Cloud Failure

**Problem:** Complete loss of hosting environment

**Recovery Strategy:**
1. **Multi-site backups** stored in different geographic locations
2. **Infrastructure as Code** for rapid environment recreation
3. **Automated restoration** with minimal manual intervention

### Business Continuity Planning

#### Recovery Time Objectives (RTO)

| Scenario | Target RTO | Achieved RTO | Recovery Method |
|----------|------------|--------------|-----------------|
| **Service Config Corruption** | 15 minutes | 5-10 minutes | Local backup restore |
| **Single Server Failure** | 2 hours | 30-60 minutes | Backup + redeploy |
| **Complete Site Loss** | 24 hours | 4-8 hours | Multi-site backup |
| **Data Center Outage** | 72 hours | 8-24 hours | Cloud migration |

#### Recovery Point Objectives (RPO)

| Data Type | Target RPO | Backup Frequency | Method |
|-----------|------------|------------------|---------|
| **Service Configurations** | 1 hour | Real-time | Git commits + automated backup |
| **Download History** | 4 hours | Every 4 hours | Database snapshots |
| **User Preferences** | 24 hours | Daily | Full configuration backup |
| **Performance Metrics** | 1 week | Weekly | Historical data export |

## Multi-Site Backup Strategy

### Geographic Distribution

```bash
# Configure multiple backup destinations
./usenet backup configure --multi-site

# Local backup (primary)
./usenet backup destination add local \
  --path /opt/backups \
  --retention 30d \
  --priority primary

# Network attached storage (secondary)
./usenet backup destination add nas \
  --path /mnt/nas/backups \
  --retention 90d \
  --priority secondary

# Cloud storage (tertiary)
./usenet backup destination add cloud \
  --type s3 \
  --bucket usenet-backups \
  --region us-west-2 \
  --retention 1y \
  --priority tertiary
```

### Automated Multi-Site Backup

```bash
# Schedule coordinated backups
./usenet backup schedule \
  --destinations local,nas,cloud \
  --frequency daily \
  --time 03:00 \
  --verify-integrity \
  --alert-on-failure
```

**Multi-Site Backup Workflow:**
```yaml
# .github/workflows/backup.yml
name: Automated Multi-Site Backup

on:
  schedule:
    - cron: '0 3 * * *'  # Daily at 3 AM
  workflow_dispatch:

jobs:
  backup:
    runs-on: self-hosted
    steps:
      - name: Create Local Backup
        run: ./usenet backup create --compress --verify
        
      - name: Upload to NAS
        run: ./usenet backup sync --destination nas --verify
        
      - name: Upload to Cloud
        run: ./usenet backup sync --destination cloud --encrypt
        
      - name: Verify All Destinations
        run: ./usenet backup verify --all-destinations
        
      - name: Cleanup Old Backups
        run: ./usenet backup cleanup --apply-retention-policy
        
      - name: Send Success Notification
        run: ./usenet notify backup-success --destinations slack,email
```

## Backup Encryption and Security

### Encrypted Backup Configuration

```bash
# Generate backup encryption key
./usenet backup configure encryption --generate-key

# Create encrypted backup
./usenet backup create --encrypt --password-file /secure/backup.key

# Restore encrypted backup
./usenet backup restore backup.tar.gz.enc --decrypt --password-file /secure/backup.key
```

### Secure Key Management

```bash
# Use hardware security module (if available)
./usenet backup configure encryption --hsm --key-id backup-key-001

# Use cloud key management
./usenet backup configure encryption \
  --kms aws \
  --key-arn arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012

# Local encrypted key storage
./usenet backup configure encryption \
  --local-key /etc/usenet/backup.key \
  --key-rotation 90d
```

### Access Control

```bash
# Configure backup access controls
./usenet backup access configure \
  --read-users admin,backup-operator \
  --write-users admin \
  --decrypt-users admin,disaster-recovery

# Audit backup access
./usenet backup access audit --period 30d --export audit-report.json
```

## Backup Monitoring and Alerting

### Backup Health Monitoring

```bash
# Monitor backup system health
./usenet backup monitor --continuous

# Configure backup alerts
./usenet alert configure backup \
  --failed-backup immediate \
  --missing-backup 25h \
  --corruption-detected immediate \
  --storage-full 48h \
  --channels email,slack,webhook
```

### Backup Metrics and Reporting

```bash
# Generate backup health report
./usenet backup report --period 30d --format json

# Monitor backup trends
./usenet backup analytics \
  --metrics size,duration,success-rate \
  --period 90d \
  --export grafana-dashboard
```

**Backup Health Dashboard:**
```bash
# Key metrics to monitor:
# - Backup success rate (target: >99%)
# - Average backup duration (track for regression)
# - Backup size trends (detect config bloat)
# - Recovery test success (monthly validation)
# - Multi-site sync status (geo-redundancy health)
```

## Database Backup Strategies

### Service Database Protection

```bash
# Individual service database backups
./usenet backup database sonarr --consistent --compress
./usenet backup database radarr --consistent --compress

# All databases with coordination
./usenet backup database --all --coordinate --verify-integrity
```

### Database-Specific Considerations

#### SQLite Databases (Most *arr services)

```bash
# Consistent SQLite backup with WAL mode
./usenet database backup sonarr \
  --wal-checkpoint \
  --verify-integrity \
  --vacuum-before-backup

# Point-in-time recovery preparation
./usenet database configure \
  --wal-mode \
  --backup-hooks \
  --transaction-log-retention 7d
```

#### PostgreSQL (if used for advanced setups)

```bash
# PostgreSQL logical backup
./usenet database backup postgres \
  --format custom \
  --compress 9 \
  --jobs 4 \
  --verbose

# Point-in-time recovery setup
./usenet database configure postgres \
  --wal-level replica \
  --archive-mode on \
  --archive-command 'cp %p /backup/wal/%f'
```

## Automated Backup Testing

### Backup Verification

```bash
# Schedule regular backup testing
./usenet backup test schedule \
  --frequency weekly \
  --restore-test-environment \
  --verify-services \
  --report-results

# Manual backup verification
./usenet backup verify latest --comprehensive
```

### Disaster Recovery Testing

```bash
# Simulate disaster recovery scenario
./usenet disaster-recovery simulate \
  --scenario complete-loss \
  --test-environment isolated \
  --restore-from latest \
  --verify-functionality

# Recovery time measurement
./usenet disaster-recovery benchmark \
  --scenarios service-corruption,server-failure,site-loss \
  --repeat 3 \
  --report recovery-times.json
```

## Backup Strategy Templates

### Home User Strategy

```bash
# Simple, cost-effective backup for home users
./usenet backup strategy apply home-user

# Configuration:
# - Daily local backups (30 day retention)
# - Weekly cloud backups (90 day retention)
# - Configuration only (no media)
# - Single encryption key
# - Email alerts on failure
```

### Professional/SMB Strategy

```bash
# Professional backup for small/medium business
./usenet backup strategy apply professional

# Configuration:
# - Hourly incremental, daily full backups
# - Multi-site geo-redundancy
# - 30/90/365 day retention tiers
# - Hardware security module encryption
# - SLA monitoring and reporting
```

### Enterprise Strategy

```bash
# Enterprise-grade backup for large deployments
./usenet backup strategy apply enterprise

# Configuration:
# - Continuous data protection
# - Multi-region replication
# - Compliance audit trails
# - Role-based access controls
# - Integration with enterprise backup systems
```

## Integration with External Backup Systems

### Enterprise Backup Integration

```bash
# Integrate with Veeam
./usenet backup integrate veeam \
  --server veeam.company.com \
  --job usenet-configuration \
  --schedule daily

# Integrate with Commvault
./usenet backup integrate commvault \
  --commserv cs.company.com \
  --subclient usenet-media-stack

# Integrate with AWS Backup
./usenet backup integrate aws-backup \
  --vault usenet-backup-vault \
  --iam-role arn:aws:iam::123456789012:role/USenetBackupRole
```

### Cloud Storage Integration

```bash
# AWS S3 integration
./usenet backup configure s3 \
  --bucket usenet-backups \
  --storage-class STANDARD_IA \
  --lifecycle-policy '{"rules":[{"transition":"GLACIER","days":90}]}'

# Azure Blob Storage
./usenet backup configure azure \
  --account usenetbackups \
  --container configurations \
  --tier cool

# Google Cloud Storage
./usenet backup configure gcs \
  --bucket usenet-backups \
  --storage-class NEARLINE \
  --location us-central1
```

## Backup Best Practices

### Backup Strategy Guidelines

1. **3-2-1 Rule Implementation**
   - 3 copies of critical data
   - 2 different storage types
   - 1 offsite copy

2. **Configuration-First Approach**
   - Backup configurations, not media
   - Media is replaceable, configurations are not
   - Focus on automation rules and quality profiles

3. **Test Recovery Regularly**
   - Monthly recovery tests
   - Document recovery procedures
   - Measure and improve recovery times

4. **Monitor Backup Health**
   - Automated backup verification
   - Alert on backup failures
   - Track backup metrics and trends

### Security Considerations

- **Encrypt all backups** at rest and in transit
- **Rotate encryption keys** regularly
- **Implement access controls** with principle of least privilege
- **Audit backup access** and maintain logs
- **Test recovery procedures** with encrypted backups

## Troubleshooting Backup Issues

### Common Backup Problems

#### Backup Size Explosion

```bash
# Diagnose backup size issues
./usenet backup analyze size --breakdown --top-contributors

# Common causes and solutions:
# - Logs included: Use --exclude-logs or --max-log-age
# - Cache files: Add cache directories to exclusions
# - Download files: Ensure --config-only mode
# - Database bloat: Run database cleanup before backup
```

#### Backup Failures

```bash
# Debug backup failures
./usenet backup debug latest-failure --verbose

# Check storage space
df -h /backup/destination

# Verify permissions
./usenet backup validate permissions

# Test backup integrity
./usenet backup verify latest --repair-if-possible
```

#### Slow Backup Performance

```bash
# Analyze backup performance
./usenet backup performance analyze --duration 10-backups

# Optimize backup speed
./usenet backup optimize \
  --compression-level 6 \
  --parallel-operations 4 \
  --network-optimization
```

## Related Documentation

- [CLI Backup Commands](../cli/backup) - Complete backup command reference
- [Custom Configurations](./custom-configs) - Protecting custom configurations
- [API Integration](./api-integration) - Backup automation via APIs
- [Troubleshooting](./troubleshooting) - Backup system debugging