# Service Audit Methodology

**Created**: 2025-12-28
**Proven On**: Tdarr (5,699 files queued, GPU VAAPI operational)

This document captures the exact research and testing pipeline used to fully configure and document each service in the stack.

---

## The 7-Step Audit Pipeline

### Step 1: Discovery (5-10 min)

**Goal**: Understand current state before changing anything.

```bash
# Check container status
sudo docker ps --filter "name=SERVICE_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check container logs for errors
sudo docker logs SERVICE_NAME --tail 50

# Inspect volume mounts (CRITICAL: container paths ≠ host paths)
sudo docker inspect SERVICE_NAME | jq '.[0].Mounts'

# Check resource usage
sudo docker stats SERVICE_NAME --no-stream

# Find config files
sudo docker exec SERVICE_NAME find /config -name "*.xml" -o -name "*.json" -o -name "*.yml" 2>/dev/null | head -20
```

**Output**: Note container paths, current config, any errors.

---

### Step 2: Research (15-30 min)

**Goal**: Find 2024-2025 best practices, hardware-specific optimizations.

**Spawn research agents in parallel:**

```
Agent 1: "[SERVICE] best practices configuration 2024 2025"
Agent 2: "[SERVICE] TRaSH Guides recommendations" (for *arr apps)
Agent 3: "[SERVICE] AMD Ryzen 7840HS / Radeon 780M optimization"
Agent 4: "[SERVICE] API documentation endpoints"
```

**Key sources to check:**
- TRaSH Guides (trash-guides.info) - *arr quality profiles
- Servarr Wiki (wiki.servarr.com) - Official docs
- Reddit (r/usenet, r/PleX, r/selfhosted) - Community knowledge
- GitHub Issues - Known bugs and workarounds
- LinuxServer.io docs - Container specifics

**Research questions:**
1. What are the optimal settings for this service?
2. Are there hardware-specific optimizations (GPU, threading)?
3. What integrations should be configured?
4. What are common pitfalls/gotchas?
5. What API endpoints are available for automation?

---

### Step 3: Hardware Audit (5-10 min)

**Goal**: Optimize for specific hardware capabilities.

**Your hardware:**
| Component | Spec | Optimization |
|-----------|------|--------------|
| CPU | AMD Ryzen 7 7840HS (8C/16T) | Parallel processing, set thread counts |
| GPU | AMD Radeon 780M (VCN4) | VAAPI transcoding, -qp not -crf |
| RAM | 96GB DDR5 | Aggressive caching, large buffers |
| Storage | 52TB NVMe (MergerFS) | Fast I/O, no spinup delays |

**Check hardware utilization:**
```bash
# CPU/RAM during service operation
htop -p $(pgrep -d, -f SERVICE_NAME)

# GPU utilization (if applicable)
watch -n1 cat /sys/class/drm/card*/device/gpu_busy_percent

# Disk I/O
iotop -p $(pgrep -f SERVICE_NAME)
```

---

### Step 4: Configuration (15-30 min)

**Goal**: Apply optimal settings discovered in research.

**Configuration methods (in order of preference):**

1. **API calls** - Scriptable, reproducible
   ```bash
   curl -s -X POST http://localhost:PORT/api/v3/config \
     -H "X-Api-Key: $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"setting": "value"}'
   ```

2. **Config files** - Edit in container or mounted volume
   ```bash
   sudo docker exec SERVICE_NAME cat /config/config.xml
   # Edit and restart
   sudo docker restart SERVICE_NAME
   ```

3. **UI configuration** - When API is broken/undocumented
   - Document the manual steps precisely
   - Note which settings MUST be done via UI

**Document API patterns:**
```bash
# Common *arr API pattern
curl -s "http://localhost:PORT/api/v3/ENDPOINT" \
  -H "X-Api-Key: $(grep -oP 'ApiKey>\K[^<]+' /path/to/config.xml)"

# Tdarr cruddb pattern
curl -s -X POST http://localhost:8265/api/v2/cruddb \
  -H "Content-Type: application/json" \
  -d '{"data":{"collection":"CollectionName","mode":"getAll"}}'
```

---

### Step 5: Validation (10-15 min)

**Goal**: Verify everything works end-to-end.

**Test checklist:**
- [ ] Service starts without errors
- [ ] Web UI accessible and responsive
- [ ] API endpoints return expected data
- [ ] Integrations with other services work
- [ ] Core functionality operates correctly
- [ ] Performance is acceptable

**Integration tests:**
```bash
# Check service health
curl -s http://localhost:PORT/api/v3/system/status | jq '.version, .isProduction'

# Test downstream integrations
# e.g., Prowlarr → Radarr sync
curl -s "http://localhost:9696/api/v1/indexer" -H "X-Api-Key: $PROWLARR_KEY" | jq 'length'
```

**Functional tests:**
- Trigger a search/scan
- Process a test file
- Verify output quality

---

### Step 6: Documentation (10-15 min)

**Goal**: Update STACK_USAGE_GUIDE.md with operational knowledge.

**Required sections:**

1. **Status table** - Current operational state
   ```markdown
   | Component | Status | Details |
   |-----------|--------|---------|
   | ServiceName | ✅ Active | Key metrics here |
   ```

2. **Configuration summary** - What's configured and why
   ```markdown
   ### ServiceName Configuration

   | Setting | Value | Rationale |
   |---------|-------|-----------|
   | ThreadCount | 8 | Match CPU cores |
   ```

3. **API reference** - Key endpoints for automation
   ```markdown
   ### ServiceName API Reference

   ```bash
   # Get status
   curl -s http://localhost:PORT/api/endpoint
   ```
   ```

4. **Gotchas** - Lessons learned, pitfalls avoided
   ```markdown
   **CRITICAL**: [Thing that breaks if you do it wrong]
   ```

---

### Step 7: Commit (2 min)

**Goal**: Preserve learnings in git history.

**Commit message format:**
```
feat(service): Brief description of what was configured

Detailed bullet points of changes:
- Setting 1 configured for reason
- Integration with X verified
- Performance optimized for hardware

Key learnings:
- Gotcha 1 discovered and documented
- API pattern documented

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Tdarr Audit Example (Reference)

### Discovery Output
```
Container: tdarr, tdarr-node
Ports: 8265 (web), 8266 (server)
Mounts: /var/mnt/pool/* → /media/* (CRITICAL path translation!)
Config DB: SQLite at /config/server/Tdarr/DB2/SQL/database.db
```

### Research Findings
- VAAPI uses -qp (0-51), NOT -crf
- API: POST /api/v2/cruddb with collection/mode/docID
- Libraries MUST be created via UI (API causes RangeError)
- VCN4 supports HEVC and AV1 encoding
- QP 18-22 is "visually lossless" range

### Hardware Optimization
- GPU workers: 2 per node (avoid VAAPI contention)
- CPU health check: 1 per node
- No CPU transcoding (GPU is faster)

### Configuration Applied
```bash
# Enable GPU plugin, disable CPU
curl -s -X POST http://localhost:8265/api/v2/cruddb \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "collection": "LibrarySettingsJSONDB",
      "mode": "update",
      "docID": "LIBRARY_ID",
      "obj": {
        "pluginIDs": [
          {"id": "Tdarr_Plugin_MC93_Migz1FFMPEG", "checked": true},
          {"id": "Tdarr_Plugin_MC93_Migz1FFMPEG_CPU", "checked": false}
        ]
      }
    }
  }'
```

### Validation
- 5,699 files discovered and queued
- GPU workers active
- No transcode errors in logs

### Commit
```
051dfa0 feat(tdarr): Complete Tdarr setup with GPU VAAPI transcoding
```

---

## Agent Delegation Pattern

For parallel research, spawn agents with specific focus:

```python
# Pseudo-code for research agent spawning
agents = [
    Task(subagent_type="general-purpose",
         prompt="Research [SERVICE] 2024-2025 best practices..."),
    Task(subagent_type="general-purpose",
         prompt="Research [SERVICE] TRaSH Guides..."),
    Task(subagent_type="general-purpose",
         prompt="Research [SERVICE] API documentation...")
]
# All run in parallel, results aggregated
```

---

## Checklist Template (Copy for each service)

```markdown
## [SERVICE] Audit

**Date**: YYYY-MM-DD
**Status**: ⬜ Pending / 🔄 In Progress / ✅ Complete

### Discovery
- [ ] Container status checked
- [ ] Volume mounts documented
- [ ] Current config reviewed
- [ ] Errors in logs noted

### Research
- [ ] 2024-2025 best practices found
- [ ] Hardware optimizations identified
- [ ] API documentation reviewed
- [ ] Common pitfalls noted

### Hardware
- [ ] CPU utilization optimized
- [ ] GPU utilization optimized (if applicable)
- [ ] Memory settings tuned
- [ ] I/O patterns reviewed

### Configuration
- [ ] Settings applied via API/config
- [ ] Integrations configured
- [ ] Performance tuning applied

### Validation
- [ ] Service health verified
- [ ] Integrations tested
- [ ] Core functionality tested
- [ ] Performance acceptable

### Documentation
- [ ] STACK_USAGE_GUIDE.md updated
- [ ] API reference added
- [ ] Gotchas documented

### Commit
- [ ] Git commit with learnings
- [ ] Commit hash: ___________
```
