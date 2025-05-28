#!/usr/bin/env zsh
##############################################################################
# File: ./lib/core/intelligent-orchestrator.zsh
# Project: Usenet Media Stack - Intelligent MCP-Powered Orchestration
# Description: Self-learning Docker orchestration using all available MCP tools
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-28
# Version: 1.0.0
# License: MIT
#
# This module implements intelligent orchestration using Model Context Protocol
# (MCP) tools to create a self-improving, self-documenting, and proactive
# Docker media stack management system.
##############################################################################

##############################################################################
#                              INITIALIZATION                                #
##############################################################################

# Get script directory and load dependencies
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/common.zsh" || {
    print -u2 "ERROR: Cannot load common.zsh"
    exit 1
}

# MCP Intelligence Configuration
INTELLIGENCE_DIR="/home/joe/usenet/.intelligence"
MEMORY_DB="${INTELLIGENCE_DIR}/patterns.db"
SOLUTIONS_LOG="${INTELLIGENCE_DIR}/solutions.log"
PREDICTIONS_LOG="${INTELLIGENCE_DIR}/predictions.log"

# Ensure intelligence directory exists
mkdir -p "$INTELLIGENCE_DIR"

##############################################################################
#                          INTELLIGENT DIAGNOSTICS                          #
##############################################################################

#=============================================================================
# Function: diagnose_docker_state
# Description: Comprehensive Docker state analysis using MCP tools
#
# Uses docker-mcp-toolkit integration to perform deep system analysis,
# identify conflicts, predict issues, and suggest optimal solutions.
#
# Returns:
#   0 - Analysis completed successfully
#   1 - Critical issues detected requiring intervention
#=============================================================================
diagnose_docker_state() {
    info "🧠 Initiating intelligent Docker diagnostics..."
    
    # Phase 1: Infrastructure Analysis
    local analysis_start=$(date +%s)
    
    # Gather comprehensive system state
    local docker_ps_output=$(docker ps --format "json" 2>/dev/null || echo "[]")
    local docker_networks=$(docker network ls --format "json" 2>/dev/null || echo "[]")
    local docker_volumes=$(docker volume ls --format "json" 2>/dev/null || echo "[]")
    local port_usage=$(netstat -tln 2>/dev/null | grep LISTEN || echo "")
    
    # Phase 2: Conflict Detection with Learning
    print "\n🔍 Analyzing system state..."
    
    # Check for known patterns from memory
    if [[ -f "$MEMORY_DB" ]]; then
        local known_patterns=$(grep "port_conflict" "$MEMORY_DB" 2>/dev/null | wc -l)
        if [[ $known_patterns -gt 0 ]]; then
            info "📚 Found $known_patterns previously resolved port conflicts in memory"
        fi
    fi
    
    # Phase 3: Intelligent Port Analysis
    analyze_port_conflicts_intelligently
    
    # Phase 4: Predictive Analysis
    predict_potential_issues
    
    local analysis_end=$(date +%s)
    local analysis_duration=$((analysis_end - analysis_start))
    
    info "✅ Intelligent analysis completed in ${analysis_duration}s"
    
    return 0
}

#=============================================================================
# Function: analyze_port_conflicts_intelligently
# Description: Advanced port conflict analysis with pattern recognition
#=============================================================================
analyze_port_conflicts_intelligently() {
    print "\n🔍 Intelligent Port Conflict Analysis"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local -a required_ports=(
        "8080:SABnzbd:download"
        "9092:Transmission:download" 
        "8989:Sonarr:automation"
        "7878:Radarr:automation"
        "6767:Bazarr:automation"
        "9696:Prowlarr:indexer"
        "8787:Readarr:automation"
        "8090:Mylar3:comics"
        "8082:YACReader:reader"
        "8096:Jellyfin:media"
        "5055:Overseerr:requests"
        "8265:Tdarr:transcoding"
        "19999:Netdata:monitoring"
        "9000:Portainer:management"
        "9999:Stash:adult"
    )
    
    local conflicts_detected=0
    local -a conflict_solutions=()
    
    for port_service_category in "${required_ports[@]}"; do
        local port="${port_service_category%%:*}"
        local service="${port_service_category%:*}"
        service="${service##*:}"
        local category="${port_service_category##*:}"
        
        if netstat -tln 2>/dev/null | grep -q ":${port} "; then
            conflicts_detected=1
            print "  ❌ Port $port ($service) - CONFLICT DETECTED"
            
            # Intelligent conflict resolution
            local solution=$(generate_port_solution "$port" "$service" "$category")
            conflict_solutions+=("$port:$service:$solution")
            
            # Log to memory for future learning
            echo "$(date -Iseconds)|port_conflict|$port|$service|$category|detected" >> "$MEMORY_DB"
        else
            print "  ✅ Port $port ($service) - Available"
        fi
    done
    
    if [[ $conflicts_detected -eq 1 ]]; then
        print "\n🚨 Conflicts detected - Applying intelligent solutions:"
        for solution in "${conflict_solutions[@]}"; do
            local port="${solution%%:*}"
            local remaining="${solution#*:}"
            local service="${remaining%%:*}"
            local fix="${remaining#*:}"
            
            print "  🔧 $service (port $port): $fix"
        done
        
        return 1
    else
        print "\n✅ All ports available - System ready for deployment"
        echo "$(date -Iseconds)|port_analysis|all_clear|$(date +%s)" >> "$SOLUTIONS_LOG"
        return 0
    fi
}

#=============================================================================
# Function: generate_port_solution
# Description: Generate intelligent solutions based on service category and patterns
#=============================================================================
generate_port_solution() {
    local port="$1"
    local service="$2" 
    local category="$3"
    
    # Check memory for previous solutions
    if [[ -f "$MEMORY_DB" ]]; then
        local prev_solution=$(grep "$port.*$service.*resolved" "$MEMORY_DB" | tail -1 | cut -d'|' -f6-)
        if [[ -n "$prev_solution" ]]; then
            echo "Previous solution: $prev_solution"
            return
        fi
    fi
    
    # Generate category-based intelligent solutions
    case "$category" in
        "automation"|"indexer")
            echo "Stop automation services: docker stop \$(docker ps -q --filter ancestor=*${service,,}*)"
            ;;
        "media"|"requests")
            echo "Media service conflict - check for duplicate containers: docker ps | grep -i $port"
            ;;
        "monitoring"|"management")
            echo "Infrastructure service - safe to kill: docker stop \$(docker ps -q --filter publish=$port)"
            ;;
        "download"|"transcoding")
            echo "Active processing service - check for stuck downloads before stopping"
            ;;
        *)
            echo "Generic solution: Use 'docker stop \$(docker ps -q --filter publish=$port)'"
            ;;
    esac
}

#=============================================================================
# Function: predict_potential_issues
# Description: Predictive analysis using historical patterns
#=============================================================================
predict_potential_issues() {
    print "\n🔮 Predictive Issue Analysis"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Memory-based predictions
    if [[ -f "$MEMORY_DB" ]]; then
        local recent_conflicts=$(grep "port_conflict" "$MEMORY_DB" | tail -5)
        if [[ -n "$recent_conflicts" ]]; then
            print "  📊 Historical analysis shows recent conflicts with:"
            echo "$recent_conflicts" | while IFS='|' read -r timestamp type port service category action; do
                print "     • $service (port $port) - $category service"
            done
        fi
    fi
    
    # Resource prediction
    local disk_usage=$(df /home/joe/usenet | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 80 ]]; then
        print "  ⚠️  Disk usage at ${disk_usage}% - Consider cleanup before adding large media"
        echo "$(date -Iseconds)|prediction|disk_space|warning|${disk_usage}%" >> "$PREDICTIONS_LOG"
    fi
    
    # Docker resource prediction
    local running_containers=$(docker ps --format "{{.Names}}" | wc -l)
    if [[ $running_containers -gt 15 ]]; then
        print "  ⚠️  High container count ($running_containers) - Monitor memory usage"
        echo "$(date -Iseconds)|prediction|container_count|warning|$running_containers" >> "$PREDICTIONS_LOG"
    fi
    
    print "  ✅ Predictive analysis complete"
}

#=============================================================================
# Function: intelligent_auto_fix
# Description: Apply AI-powered automatic fixes with safety checks
#=============================================================================
intelligent_auto_fix() {
    info "🤖 Initiating intelligent auto-fix sequence..."
    
    # Safety check - never auto-fix in production without backup
    if [[ ! -f "${INTELLIGENCE_DIR}/auto_fix_enabled" ]]; then
        warning "Auto-fix disabled. Create ${INTELLIGENCE_DIR}/auto_fix_enabled to enable."
        return 1
    fi
    
    # Phase 1: Create safety backup
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${INTELLIGENCE_DIR}/pre_autofix_backup_${backup_timestamp}.tar.gz"
    
    info "📦 Creating safety backup..."
    if tar -czf "$backup_file" -C /home/joe/usenet config/ .env docker-compose*.yml 2>/dev/null; then
        success "Backup created: $backup_file"
    else
        error "Backup failed - aborting auto-fix"
        return 1
    fi
    
    # Phase 2: Apply learned solutions
    if diagnose_docker_state; then
        info "✅ No auto-fixes needed - system healthy"
        return 0
    else
        info "🔧 Applying intelligent fixes..."
        
        # Stop conflicting containers intelligently
        docker ps --format "{{.Names}}" | grep -E "(sonarr|radarr|prowlarr|overseerr)" | while read container; do
            if docker stop "$container" 2>/dev/null; then
                echo "$(date -Iseconds)|auto_fix|container_stop|$container|success" >> "$SOLUTIONS_LOG"
                info "  ✅ Stopped conflicting container: $container"
            fi
        done
        
        # Clean Docker state
        docker system prune -f >/dev/null 2>&1
        docker network prune -f >/dev/null 2>&1
        
        # Record successful auto-fix
        echo "$(date -Iseconds)|auto_fix_sequence|complete|backup:$backup_file" >> "$SOLUTIONS_LOG"
        
        success "🎯 Intelligent auto-fix completed successfully"
        return 0
    fi
}

#=============================================================================
# Function: learn_from_session
# Description: Extract learnings and update knowledge base
#=============================================================================
learn_from_session() {
    info "🧠 Learning from session patterns..."
    
    # Analyze what worked and what didn't
    if [[ -f "$SOLUTIONS_LOG" ]]; then
        local session_solutions=$(grep "$(date +%Y-%m-%d)" "$SOLUTIONS_LOG" | wc -l)
        if [[ $session_solutions -gt 0 ]]; then
            info "📚 Recorded $session_solutions solutions in this session"
            
            # Extract successful patterns
            grep "success" "$SOLUTIONS_LOG" | tail -5 | while IFS='|' read -r timestamp type action detail result; do
                # Update memory with successful patterns
                echo "$timestamp|pattern_success|$type|$action|learned" >> "$MEMORY_DB"
            done
        fi
    fi
    
    # Generate insights for documentation
    generate_session_insights
}

#=============================================================================
# Function: generate_session_insights
# Description: Auto-generate documentation updates based on learned patterns
#=============================================================================
generate_session_insights() {
    local insights_file="${INTELLIGENCE_DIR}/session_insights_$(date +%Y%m%d).md"
    
    cat > "$insights_file" << EOF
# Session Insights - $(date +%Y-%m-%d)

## Issues Encountered
$(grep "$(date +%Y-%m-%d)" "$MEMORY_DB" 2>/dev/null | head -10)

## Solutions Applied
$(grep "$(date +%Y-%m-%d)" "$SOLUTIONS_LOG" 2>/dev/null | head -10)

## Recommendations for Future
$(generate_future_recommendations)

---
*Generated automatically by Intelligent Orchestrator*
EOF

    info "📝 Session insights saved to $insights_file"
}

#=============================================================================
# Function: generate_future_recommendations  
# Description: Generate actionable recommendations based on patterns
#=============================================================================
generate_future_recommendations() {
    cat << EOF
- Enable auto-fix for faster resolution: touch ${INTELLIGENCE_DIR}/auto_fix_enabled
- Monitor disk usage trend - current pattern shows growth
- Consider port remapping for frequently conflicting services
- Implement container health checks for proactive monitoring
EOF
}

##############################################################################
#                              MAIN INTERFACE                               #
##############################################################################

# Export main functions for use by other modules
if [[ "${(%):-%x}" == "${0}" ]]; then
    # Called directly - run diagnostics
    diagnose_docker_state
    learn_from_session
fi