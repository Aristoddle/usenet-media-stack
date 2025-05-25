# Advanced Troubleshooting

Comprehensive troubleshooting guide for complex issues in your Usenet Media Stack. This guide covers systematic debugging approaches, advanced diagnostic tools, and resolution strategies for challenging problems.

## Troubleshooting Philosophy

### Systematic Debugging Approach

```
Diagnostic Framework:
├── 1. Problem Identification
│   ├── Symptom analysis and classification
│   ├── Impact assessment and urgency
│   └── Initial hypothesis formation
├── 2. Information Gathering
│   ├── System state analysis
│   ├── Log examination and correlation
│   └── Performance metrics review
├── 3. Root Cause Analysis
│   ├── Component isolation testing
│   ├── Configuration validation
│   └── Environmental factor analysis
├── 4. Solution Implementation
│   ├── Staged remediation approach
│   ├── Change impact assessment
│   └── Rollback planning
└── 5. Prevention and Documentation
    ├── Process improvement
    ├── Monitoring enhancement
    └── Knowledge base updates
```

### Issue Classification System

| Severity | Description | Response Time | Examples |
|----------|-------------|---------------|----------|
| **Critical** | Complete service outage | Immediate | All services down, data corruption |
| **High** | Major functionality impacted | 2 hours | GPU transcoding failed, storage unavailable |
| **Medium** | Partial functionality affected | 24 hours | Single service issues, performance degradation |
| **Low** | Minor issues, cosmetic problems | 72 hours | UI glitches, non-critical warnings |

## Advanced Diagnostic Tools

### Built-in Diagnostic Framework

```bash
# Comprehensive system analysis
./usenet diagnose --comprehensive --export-report

# Component-specific diagnostics
./usenet diagnose hardware --deep-scan --benchmark
./usenet diagnose storage --performance-analysis --health-check
./usenet diagnose network --connectivity-matrix --latency-analysis
./usenet diagnose services --dependency-graph --api-validation

# Performance profiling
./usenet profile --duration 30m --output detailed-profile.json
```

### Enhanced Logging and Monitoring

```bash
# Enable debug logging across all services
./usenet logging set-level debug --all-services

# Centralized log analysis
./usenet logs analyze --pattern-detection --anomaly-detection

# Real-time monitoring with alerting
./usenet monitor --live --alert-threshold high --duration continuous
```

### System State Capture

```bash
# Generate comprehensive support bundle
./usenet support bundle create \
  --include-configs \
  --include-logs \
  --include-metrics \
  --include-system-info \
  --anonymize-sensitive \
  --compress

# System snapshot for state comparison
./usenet snapshot create --name "pre-troubleshooting-$(date +%Y%m%d_%H%M)"
```

## Hardware-Related Issues

### GPU Transcoding Problems

#### Issue: Hardware Transcoding Not Working

**Symptoms:**
- High CPU usage during transcoding
- Slow transcoding speeds (2-5 FPS instead of 30+ FPS)
- Error messages about GPU not found

**Diagnostic Steps:**
```bash
# 1. Verify GPU detection
./usenet hardware list --detailed

# 2. Check GPU drivers
nvidia-smi  # For NVIDIA
vainfo      # For AMD/Intel

# 3. Test GPU access in containers
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# 4. Verify Jellyfin GPU configuration
./usenet services logs jellyfin | grep -i "gpu\|hardware\|nvenc\|vaapi"

# 5. Test transcoding manually
docker exec jellyfin ffmpeg -hwaccel cuda -i /media/test.mkv -c:v h264_nvenc -t 10 /tmp/test_output.mp4
```

**Common Solutions:**
```bash
# Reinstall GPU drivers
./usenet hardware install-drivers --force

# Reset GPU configuration
./usenet hardware configure --reset --auto-detect

# Update Docker GPU runtime
sudo systemctl restart docker
./usenet services restart jellyfin

# Generate new hardware-optimized configuration
./usenet hardware optimize --force-regenerate
```

#### Issue: GPU Memory Errors

**Symptoms:**
- CUDA out of memory errors
- Transcoding randomly failing
- GPU utilization spikes to 100%

**Diagnostic and Resolution:**
```bash
# Monitor GPU memory usage
nvidia-smi -l 1  # Monitor every second

# Check Jellyfin transcoding settings
./usenet services config jellyfin --show-transcoding-settings

# Optimize GPU memory allocation
./usenet hardware optimize --gpu-memory-tuning --max-concurrent-streams 4

# Configure transcoding limits
./usenet services configure jellyfin \
  --max-concurrent-transcodes 2 \
  --transcode-temp-path /mnt/fast_storage/transcode
```

### Storage Performance Issues

#### Issue: Slow File Operations

**Symptoms:**
- Long import times in Sonarr/Radarr
- Slow media library scans
- High I/O wait times

**Diagnostic Steps:**
```bash
# 1. Storage performance analysis
./usenet storage benchmark --comprehensive

# 2. I/O monitoring
iotop -a  # Monitor I/O activity
iostat -x 1  # Extended I/O statistics

# 3. Filesystem analysis
df -h  # Check disk usage
mount | grep storage  # Verify mount options

# 4. Check for storage errors
dmesg | grep -i "error\|fail\|timeout"
smartctl -a /dev/sda  # Check disk health
```

**Performance Optimization:**
```bash
# Optimize mount options for media workloads
./usenet storage optimize --workload media-server

# Enable filesystem optimizations
sudo tune2fs -o journal_data_writeback /dev/sda1

# Configure read-ahead for HDDs
echo 4096 | sudo tee /sys/block/sda/queue/read_ahead_kb

# Use faster storage for transcoding
./usenet hardware configure --transcode-path /mnt/nvme_cache
```

## Service Integration Issues

### API Communication Problems

#### Issue: Services Can't Communicate

**Symptoms:**
- Sonarr can't connect to download clients
- Prowlarr sync failures
- Overseerr can't reach Sonarr/Radarr

**Diagnostic Framework:**
```bash
# 1. Network connectivity test
./usenet network test --service-matrix

# 2. API endpoint validation
./usenet api test --all-services --verbose

# 3. Check service URLs and API keys
./usenet services config --show-api-endpoints

# 4. Container network analysis
docker network ls
docker network inspect usenet-stack
```

**Resolution Steps:**
```bash
# Regenerate API keys
./usenet config generate-keys --force

# Reset network configuration
docker network rm usenet-stack
./usenet network create --optimized

# Restart services in dependency order
./usenet services restart --dependency-order

# Verify API connectivity
./usenet api test --comprehensive --fix-common-issues
```

### Database Corruption Issues

#### Issue: Service Database Corruption

**Symptoms:**
- Service won't start
- Database errors in logs
- Data inconsistencies

**Recovery Process:**
```bash
# 1. Stop affected service
./usenet services stop sonarr

# 2. Backup corrupted database
cp config/sonarr/sonarr.db config/sonarr/sonarr.db.corrupted.$(date +%s)

# 3. Attempt database repair
sqlite3 config/sonarr/sonarr.db ".recover" | sqlite3 config/sonarr/sonarr_recovered.db

# 4. Verify database integrity
sqlite3 config/sonarr/sonarr_recovered.db "PRAGMA integrity_check;"

# 5. Restore from backup if repair fails
./usenet backup restore latest --services sonarr
```

## Performance Troubleshooting

### High Resource Usage

#### Issue: Excessive Memory Consumption

**Diagnostic Process:**
```bash
# 1. Identify memory-hungry services
./usenet monitor memory --top-consumers --detailed

# 2. Memory leak detection
./usenet monitor memory --leak-detection --duration 2h

# 3. Analyze memory allocation patterns
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# 4. Check for memory-mapped files
lsof | grep -E "(deleted|tmp)" | head -20
```

**Memory Optimization:**
```bash
# Configure memory limits
./usenet services configure --memory-limits auto

# Enable garbage collection tuning
./usenet services configure sonarr --gc-optimization
./usenet services configure radarr --gc-optimization

# Clear caches and temporary files
./usenet maintenance clear-caches --all-services
```

#### Issue: High CPU Usage

**Analysis and Resolution:**
```bash
# 1. CPU usage analysis
top -H -p $(pgrep -d',' -f jellyfin)  # Per-thread analysis
perf top -p $(pgrep jellyfin)  # Performance profiling

# 2. Identify CPU-intensive operations
./usenet monitor cpu --process-breakdown --duration 15m

# 3. Check for inefficient operations
./usenet services logs --pattern "slow query\|timeout\|retry"

# 4. Optimize CPU usage
./usenet hardware optimize --cpu-tuning
./usenet services configure --cpu-limits balanced
```

## Network and Connectivity Issues

### Cloudflare Tunnel Problems

#### Issue: External Access Not Working

**Diagnostic Steps:**
```bash
# 1. Check tunnel status
./usenet tunnel status --detailed

# 2. Verify DNS records
dig jellyfin.yourdomain.com
nslookup jellyfin.yourdomain.com

# 3. Test local service access
curl -I http://localhost:8096/health

# 4. Check tunnel logs
./usenet tunnel logs --tail 100

# 5. Validate Cloudflare configuration
./usenet tunnel validate --test-endpoints
```

**Resolution Process:**
```bash
# Reset tunnel configuration
./usenet tunnel reset --preserve-domain

# Recreate tunnel with debugging
./usenet tunnel setup --debug --domain yourdomain.com

# Test tunnel connectivity
./usenet tunnel test --all-endpoints --verbose
```

### Container Networking Issues

#### Issue: Services Can't Reach Each Other

**Network Troubleshooting:**
```bash
# 1. Inspect Docker networks
docker network ls
docker network inspect usenet-stack

# 2. Test inter-container connectivity
docker exec sonarr ping radarr
docker exec sonarr curl -I http://prowlarr:9696/api/v1/health

# 3. Check port bindings
docker port jellyfin
netstat -tlnp | grep :8096

# 4. Analyze network traffic
tcpdump -i docker0 -n host 172.20.0.5  # Replace with container IP
```

**Network Reset and Optimization:**
```bash
# Complete network reset
docker-compose down
docker network rm usenet-stack
docker network prune -f

# Recreate optimized network
./usenet network create --mtu 9000 --subnet 172.20.0.0/16

# Restart services with network debugging
./usenet services start --network-debug
```

## Configuration Issues

### Environment and Configuration Problems

#### Issue: Services Using Wrong Configuration

**Configuration Audit:**
```bash
# 1. Validate all configurations
./usenet validate --strict --all-categories

# 2. Compare with known good configuration
./usenet config diff --base backup-20240115.tar.gz --current live

# 3. Check environment variable propagation
./usenet config show --resolved --all-services

# 4. Verify file permissions
./usenet config validate permissions --fix
```

**Configuration Reset:**
```bash
# Reset single service configuration
./usenet services reset sonarr --preserve-data

# Reset all configurations to defaults
./usenet config reset --preserve-api-keys --backup-current

# Apply hardware-optimized defaults
./usenet deploy --reset-config --hardware-optimize
```

### Docker Compose Issues

#### Issue: Services Won't Start

**Container Debugging:**
```bash
# 1. Check container status
docker ps -a

# 2. Examine container logs
docker logs jellyfin --tail 50

# 3. Inspect container configuration
docker inspect jellyfin | jq '.Config'

# 4. Test container startup manually
docker run --rm -it \
  --name jellyfin-debug \
  -v ./config/jellyfin:/config \
  jellyfin/jellyfin:latest \
  /bin/bash
```

**Compose File Validation:**
```bash
# Validate compose syntax
docker-compose config --quiet

# Check for port conflicts
netstat -tlnp | grep -E ":8096|:8989|:7878"

# Validate volume mounts
./usenet storage validate --docker-mounts

# Test compose file with minimal services
docker-compose up jellyfin prowlarr
```

## Advanced Debugging Techniques

### System-Level Debugging

#### Kernel and System Issues

```bash
# 1. Check kernel messages
dmesg | tail -50
journalctl -xe

# 2. Monitor system calls
strace -p $(pgrep jellyfin) -f -e trace=file

# 3. Analyze system performance
sar -A 1 10  # System activity report
vmstat 1 10  # Virtual memory statistics

# 4. Check system limits
ulimit -a
cat /proc/sys/fs/file-max
```

#### Container Runtime Debugging

```bash
# 1. Docker daemon debugging
sudo dockerd --debug --log-level debug

# 2. Container resource analysis
docker stats --no-stream

# 3. Container filesystem analysis
docker exec jellyfin df -h
docker exec jellyfin mount | grep -E "(tmpfs|bind)"

# 4. Container process analysis
docker exec jellyfin ps aux
docker exec jellyfin top
```

### Application-Level Debugging

#### Service-Specific Debugging

**Jellyfin Debugging:**
```bash
# Enable detailed FFmpeg logging
docker exec jellyfin \
  sed -i 's/<LogLevel>Information<\/LogLevel>/<LogLevel>Debug<\/LogLevel>/' \
  /config/logging.json

# Monitor transcoding in real-time
docker exec jellyfin tail -f /config/log/jellyfin*.log | grep -i transcode

# Test hardware acceleration manually
docker exec jellyfin ffmpeg \
  -hwaccel cuda \
  -i /media/test.mkv \
  -c:v h264_nvenc \
  -t 10 \
  /tmp/test.mp4 \
  -v debug
```

**Sonarr/Radarr Debugging:**
```bash
# Enable trace logging
./usenet services configure sonarr --log-level trace

# Monitor API requests
./usenet services logs sonarr | grep -E "POST|GET|PUT|DELETE"

# Database query analysis
sqlite3 config/sonarr/sonarr.db ".trace stdout"
```

## Performance Profiling

### Application Performance Analysis

```bash
# 1. CPU profiling
perf record -g ./usenet services start jellyfin
perf report

# 2. Memory profiling
valgrind --tool=massif docker exec jellyfin /usr/lib/jellyfin/bin/jellyfin

# 3. I/O profiling
iotrace -p $(pgrep jellyfin) -d 60

# 4. Network profiling
nethogs -p
iftop -i docker0
```

### Database Performance Analysis

```bash
# SQLite query optimization
sqlite3 config/sonarr/sonarr.db << 'EOF'
.timer on
.explain query plan
SELECT * FROM Series WHERE TvdbId = 12345;
.quit
EOF

# Database statistics
./usenet database analyze --all-services --optimization-recommendations
```

## Automated Diagnostics

### Health Check Automation

```bash
# Automated health monitoring
./usenet monitor health \
  --continuous \
  --auto-remediate \
  --escalation-policy email,slack

# Predictive failure detection
./usenet analyze trends \
  --predict-failures \
  --recommend-maintenance \
  --alert-threshold medium
```

### Self-Healing Capabilities

```bash
# Enable auto-recovery for common issues
./usenet configure auto-healing \
  --restart-failed-services \
  --clear-stuck-downloads \
  --cleanup-temp-files \
  --optimize-databases

# Configure recovery policies
./usenet recovery-policy configure \
  --max-restart-attempts 3 \
  --restart-delay 30s \
  --escalation-timeout 10m
```

## Troubleshooting Workflows

### Standard Operating Procedures

#### Critical Issue Response

```bash
#!/bin/bash
# Critical issue response workflow

# 1. Immediate assessment
./usenet services health --emergency-mode

# 2. Create system snapshot
./usenet snapshot create --emergency --name "critical-$(date +%Y%m%d_%H%M)"

# 3. Generate support bundle
./usenet support bundle create --priority critical --upload

# 4. Attempt automated recovery
./usenet recover --auto --safe-mode

# 5. Escalate if needed
if ! ./usenet validate --critical-only; then
    ./usenet alert escalate --level critical --include-snapshot
fi
```

#### Performance Degradation Response

```bash
#!/bin/bash
# Performance degradation workflow

# 1. Baseline comparison
./usenet performance compare --baseline last-week --alert-on-regression

# 2. Resource analysis
./usenet monitor resources --detailed --duration 15m

# 3. Bottleneck identification
./usenet diagnose bottlenecks --auto-detect --recommendations

# 4. Optimization application
./usenet optimize --auto --measure-improvement

# 5. Validation and monitoring
./usenet validate performance --continuous --duration 1h
```

## Documentation and Knowledge Management

### Issue Documentation

```bash
# Create troubleshooting knowledge base entry
./usenet kb create \
  --issue "GPU transcoding failure" \
  --symptoms "High CPU, slow transcoding" \
  --resolution "Driver reinstall + config reset" \
  --prevention "Regular driver updates"

# Search knowledge base
./usenet kb search "transcoding" --similar-issues

# Update resolution procedures
./usenet kb update --issue-id 123 --add-resolution-step "Verify container GPU access"
```

### Incident Tracking

```bash
# Create incident record
./usenet incident create \
  --severity high \
  --title "Jellyfin GPU transcoding failure" \
  --description "Hardware transcoding stopped working after system update"

# Update incident with findings
./usenet incident update 456 \
  --add-finding "NVIDIA driver version incompatibility" \
  --add-action "Downgrade to driver 545.29.06"

# Close incident with resolution
./usenet incident close 456 \
  --resolution "Driver downgrade successful" \
  --prevention "Pin driver version in package manager"
```

## Getting Expert Help

### Support Bundle Generation

```bash
# Comprehensive support bundle
./usenet support bundle create \
  --include-all \
  --anonymize \
  --compress \
  --upload-to support-portal

# Targeted support bundle for specific issues
./usenet support bundle create \
  --focus gpu-transcoding \
  --include-benchmarks \
  --include-hardware-info
```

### Community Support

```bash
# Generate shareable configuration (anonymized)
./usenet config share --anonymize --focus-issue transcoding

# Create reproducible test case
./usenet test-case create \
  --minimal-reproduction \
  --include-sample-media \
  --document-steps
```

## Prevention and Monitoring

### Proactive Monitoring

```bash
# Set up comprehensive monitoring
./usenet monitor setup \
  --metrics performance,health,errors \
  --alerts progressive \
  --dashboards grafana \
  --retention 90d

# Predictive analytics
./usenet analytics configure \
  --failure-prediction \
  --capacity-planning \
  --trend-analysis \
  --monthly-reports
```

### Preventive Maintenance

```bash
# Automated maintenance schedule
./usenet maintenance schedule \
  --daily "cleanup temp files, check disk space" \
  --weekly "database optimization, log rotation" \
  --monthly "driver updates, security patches" \
  --quarterly "full system health check"
```

## Related Documentation

- [Performance Tuning](./performance) - Optimize system performance
- [Custom Configurations](./custom-configs) - Configuration troubleshooting
- [CLI Reference](../cli/) - Command-line troubleshooting tools
- [Architecture Documentation](../architecture/) - System design understanding