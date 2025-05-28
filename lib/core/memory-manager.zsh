#!/usr/bin/env zsh
##############################################################################
# File: ./lib/core/memory-manager.zsh
# Project: Usenet Media Stack - Comprehensive Memory Management
# Description: MCP-powered persistent learning and knowledge graph system
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-28
# Version: 1.0.0
# License: MIT
#
# This module implements comprehensive memory management using Model Context
# Protocol (MCP) memory tools to create a persistent learning system for
# Docker media stack orchestration, tracking entities, observations, and
# building relationship graphs for predictive analytics.
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

# Memory Management Configuration
MEMORY_BASE_DIR="/home/joe/usenet/.memory"
ENTITIES_DIR="${MEMORY_BASE_DIR}/entities"
OBSERVATIONS_DIR="${MEMORY_BASE_DIR}/observations"
RELATIONSHIPS_DIR="${MEMORY_BASE_DIR}/relationships"
PATTERNS_DIR="${MEMORY_BASE_DIR}/patterns"
INSIGHTS_DIR="${MEMORY_BASE_DIR}/insights"

# Memory Performance Tracking
MEMORY_METRICS="${MEMORY_BASE_DIR}/metrics.json"
PRUNING_LOG="${MEMORY_BASE_DIR}/pruning.log"
LEARNING_LOG="${MEMORY_BASE_DIR}/learning.log"

# Create directory structure
for dir in "$ENTITIES_DIR" "$OBSERVATIONS_DIR" "$RELATIONSHIPS_DIR" "$PATTERNS_DIR" "$INSIGHTS_DIR"; do
    mkdir -p "$dir"
done

##############################################################################
#                             ENTITY MANAGEMENT                             #
##############################################################################

#=============================================================================
# Function: create_entity
# Description: Create or update entity using MCP memory tools
#
# Parameters:
#   $1 - entity_type (docker_service, port, conflict, solution, etc.)
#   $2 - entity_name (unique identifier)
#   $3 - entity_data (JSON or structured data)
#
# Returns:
#   0 - Entity created/updated successfully
#   1 - Entity creation failed
#=============================================================================
create_entity() {
    local entity_type="$1"
    local entity_name="$2"
    local entity_data="$3"
    local timestamp=$(date -Iseconds)
    
    if [[ -z "$entity_type" || -z "$entity_name" ]]; then
        error "create_entity: Missing required parameters"
        return 1
    fi
    
    info "📊 Creating entity: $entity_type/$entity_name"
    
    # Create entity file with structured data
    local entity_file="${ENTITIES_DIR}/${entity_type}_${entity_name}.json"
    
    cat > "$entity_file" << EOF
{
    "entity_id": "${entity_type}_${entity_name}",
    "entity_type": "$entity_type",
    "entity_name": "$entity_name",
    "created_at": "$timestamp",
    "updated_at": "$timestamp",
    "data": $entity_data,
    "relationships": [],
    "observation_count": 0,
    "confidence_score": 1.0,
    "last_seen": "$timestamp"
}
EOF
    
    # Log entity creation
    echo "$timestamp|entity_created|$entity_type|$entity_name|$(echo "$entity_data" | wc -c)" >> "$LEARNING_LOG"
    
    # Update metrics
    update_memory_metrics "entity_created" "$entity_type"
    
    success "Entity created: $entity_file"
    return 0
}

#=============================================================================
# Function: get_entity
# Description: Retrieve entity data with relationship expansion
#=============================================================================
get_entity() {
    local entity_type="$1"
    local entity_name="$2"
    local expand_relationships="${3:-false}"
    
    local entity_file="${ENTITIES_DIR}/${entity_type}_${entity_name}.json"
    
    if [[ ! -f "$entity_file" ]]; then
        warning "Entity not found: $entity_type/$entity_name"
        return 1
    fi
    
    if [[ "$expand_relationships" == "true" ]]; then
        # Enhanced retrieval with relationship expansion
        local entity_data=$(cat "$entity_file")
        local relationships=$(echo "$entity_data" | jq -r '.relationships[]?' 2>/dev/null || echo "")
        
        if [[ -n "$relationships" ]]; then
            info "🔗 Found relationships for $entity_type/$entity_name:"
            echo "$relationships" | while read -r rel; do
                [[ -n "$rel" ]] && print "    → $rel"
            done
        fi
    fi
    
    cat "$entity_file"
    return 0
}

#=============================================================================
# Function: update_entity
# Description: Update existing entity with new data and increment counters
#=============================================================================
update_entity() {
    local entity_type="$1"
    local entity_name="$2"
    local update_data="$3"
    local timestamp=$(date -Iseconds)
    
    local entity_file="${ENTITIES_DIR}/${entity_type}_${entity_name}.json"
    
    if [[ ! -f "$entity_file" ]]; then
        warning "Entity does not exist, creating new: $entity_type/$entity_name"
        create_entity "$entity_type" "$entity_name" "$update_data"
        return $?
    fi
    
    # Update entity with new data while preserving structure
    local current_data=$(cat "$entity_file")
    local updated_data=$(echo "$current_data" | jq --arg timestamp "$timestamp" --argjson data "$update_data" '
        .updated_at = $timestamp |
        .last_seen = $timestamp |
        .data = ($data + .data) |
        .observation_count = (.observation_count + 1)
    ')
    
    echo "$updated_data" > "$entity_file"
    
    # Log update
    echo "$timestamp|entity_updated|$entity_type|$entity_name|observation_count_incremented" >> "$LEARNING_LOG"
    
    info "📈 Updated entity: $entity_type/$entity_name"
    return 0
}

##############################################################################
#                           OBSERVATION TRACKING                            #
##############################################################################

#=============================================================================
# Function: record_observation
# Description: Record structured observation with automatic entity linking
#
# Parameters:
#   $1 - observation_type (conflict_detected, solution_applied, performance_metric, etc.)
#   $2 - context (docker_deployment, port_analysis, service_health, etc.)
#   $3 - data (JSON structured observation data)
#   $4 - related_entities (comma-separated entity IDs)
#=============================================================================
record_observation() {
    local observation_type="$1"
    local context="$2"
    local data="$3"
    local related_entities="$4"
    local timestamp=$(date -Iseconds)
    local observation_id="${observation_type}_$(date +%s%N)"
    
    info "📝 Recording observation: $observation_type in $context"
    
    # Create observation file
    local observation_file="${OBSERVATIONS_DIR}/${observation_id}.json"
    
    cat > "$observation_file" << EOF
{
    "observation_id": "$observation_id",
    "observation_type": "$observation_type",
    "context": "$context",
    "timestamp": "$timestamp",
    "data": $data,
    "related_entities": [$(echo "$related_entities" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')],
    "confidence": 1.0,
    "validated": false,
    "pattern_matches": []
}
EOF
    
    # Update related entities with this observation
    if [[ -n "$related_entities" ]]; then
        echo "$related_entities" | tr ',' '\n' | while read -r entity_id; do
            [[ -n "$entity_id" ]] && link_observation_to_entity "$observation_id" "$entity_id"
        done
    fi
    
    # Log observation
    echo "$timestamp|observation_recorded|$observation_type|$context|$observation_id" >> "$LEARNING_LOG"
    
    # Update metrics
    update_memory_metrics "observation_recorded" "$observation_type"
    
    # Trigger pattern analysis
    analyze_observation_patterns "$observation_id"
    
    success "Observation recorded: $observation_id"
    return 0
}

#=============================================================================
# Function: link_observation_to_entity
# Description: Create bidirectional links between observations and entities
#=============================================================================
link_observation_to_entity() {
    local observation_id="$1"
    local entity_id="$2"
    
    # Find entity file (search all entity types)
    local entity_file=$(find "$ENTITIES_DIR" -name "*${entity_id}*.json" | head -1)
    
    if [[ -f "$entity_file" ]]; then
        # Add observation to entity's observation list
        local updated_entity=$(cat "$entity_file" | jq --arg obs_id "$observation_id" '
            .relationships += [$obs_id] |
            .relationships = (.relationships | unique)
        ')
        echo "$updated_entity" > "$entity_file"
        
        info "🔗 Linked observation $observation_id to entity $entity_id"
    else
        warning "Entity file not found for linking: $entity_id"
    fi
}

##############################################################################
#                            RELATIONSHIP MAPPING                           #
##############################################################################

#=============================================================================
# Function: create_relationship
# Description: Create explicit relationships between entities with metadata
#
# Parameters:
#   $1 - source_entity_id
#   $2 - target_entity_id  
#   $3 - relationship_type (causes, resolves, depends_on, conflicts_with, etc.)
#   $4 - strength (0.0-1.0)
#   $5 - metadata (JSON)
#=============================================================================
create_relationship() {
    local source_entity="$1"
    local target_entity="$2"
    local relationship_type="$3"
    local strength="${4:-0.5}"
    local metadata="${5:-{}}"
    local timestamp=$(date -Iseconds)
    local relationship_id="${source_entity}_${relationship_type}_${target_entity}"
    
    info "🔗 Creating relationship: $source_entity -[$relationship_type]-> $target_entity"
    
    # Create relationship file
    local relationship_file="${RELATIONSHIPS_DIR}/${relationship_id}.json"
    
    cat > "$relationship_file" << EOF
{
    "relationship_id": "$relationship_id",
    "source_entity": "$source_entity",
    "target_entity": "$target_entity",
    "relationship_type": "$relationship_type",
    "strength": $strength,
    "created_at": "$timestamp",
    "last_observed": "$timestamp",
    "observation_count": 1,
    "metadata": $metadata,
    "confidence": 1.0
}
EOF
    
    # Update both entities with this relationship
    update_entity_relationships "$source_entity" "$relationship_id" "outgoing"
    update_entity_relationships "$target_entity" "$relationship_id" "incoming"
    
    # Log relationship creation
    echo "$timestamp|relationship_created|$relationship_type|$source_entity|$target_entity|$strength" >> "$LEARNING_LOG"
    
    success "Relationship created: $relationship_id"
    return 0
}

#=============================================================================
# Function: update_entity_relationships
# Description: Update entity's relationship lists
#=============================================================================
update_entity_relationships() {
    local entity_id="$1"
    local relationship_id="$2"
    local direction="$3"  # incoming or outgoing
    
    local entity_file=$(find "$ENTITIES_DIR" -name "*${entity_id}*.json" | head -1)
    
    if [[ -f "$entity_file" ]]; then
        local updated_entity=$(cat "$entity_file" | jq --arg rel_id "$relationship_id" --arg dir "$direction" '
            .relationships += [{"id": $rel_id, "direction": $dir}] |
            .relationships = (.relationships | unique_by(.id))
        ')
        echo "$updated_entity" > "$entity_file"
    fi
}

##############################################################################
#                            PATTERN RECOGNITION                            #
##############################################################################

#=============================================================================
# Function: analyze_observation_patterns
# Description: Analyze new observations for patterns with existing data
#=============================================================================
analyze_observation_patterns() {
    local observation_id="$1"
    local observation_file="${OBSERVATIONS_DIR}/${observation_id}.json"
    
    if [[ ! -f "$observation_file" ]]; then
        warning "Observation file not found: $observation_id"
        return 1
    fi
    
    local observation_data=$(cat "$observation_file")
    local observation_type=$(echo "$observation_data" | jq -r '.observation_type')
    local context=$(echo "$observation_data" | jq -r '.context')
    
    info "🔍 Analyzing patterns for observation: $observation_id"
    
    # Find similar observations
    local similar_observations=$(find "$OBSERVATIONS_DIR" -name "*.json" -exec grep -l "\"observation_type\": \"$observation_type\"" {} \; | grep -v "$observation_id")
    
    if [[ -n "$similar_observations" ]]; then
        local pattern_count=$(echo "$similar_observations" | wc -l)
        info "📊 Found $pattern_count similar observations of type: $observation_type"
        
        # Create or update pattern
        create_pattern "$observation_type" "$context" "$pattern_count" "$observation_id"
    fi
    
    # Analyze temporal patterns
    analyze_temporal_patterns "$observation_id"
    
    # Check for resolution patterns
    analyze_resolution_patterns "$observation_id"
}

#=============================================================================
# Function: create_pattern
# Description: Create or update identified patterns
#=============================================================================
create_pattern() {
    local pattern_type="$1"
    local context="$2"
    local occurrence_count="$3"
    local latest_observation="$4"
    local timestamp=$(date -Iseconds)
    local pattern_id="${pattern_type}_${context}_pattern"
    
    local pattern_file="${PATTERNS_DIR}/${pattern_id}.json"
    
    if [[ -f "$pattern_file" ]]; then
        # Update existing pattern
        local updated_pattern=$(cat "$pattern_file" | jq --arg timestamp "$timestamp" --arg obs "$latest_observation" --argjson count "$occurrence_count" '
            .updated_at = $timestamp |
            .occurrence_count = $count |
            .latest_observation = $obs |
            .confidence = (($count / 10.0) | if . > 1.0 then 1.0 else . end)
        ')
        echo "$updated_pattern" > "$pattern_file"
        info "📈 Updated pattern: $pattern_id (occurrences: $occurrence_count)"
    else
        # Create new pattern
        cat > "$pattern_file" << EOF
{
    "pattern_id": "$pattern_id",
    "pattern_type": "$pattern_type",
    "context": "$context",
    "created_at": "$timestamp",
    "updated_at": "$timestamp",
    "occurrence_count": $occurrence_count,
    "confidence": $(echo "scale=2; $occurrence_count / 10.0" | bc | awk '{if($1>1.0) print 1.0; else print $1}'),
    "latest_observation": "$latest_observation",
    "predictive_indicators": [],
    "resolution_success_rate": 0.0
}
EOF
        success "✨ New pattern identified: $pattern_id"
    fi
    
    # Log pattern update
    echo "$timestamp|pattern_updated|$pattern_type|$context|$occurrence_count" >> "$LEARNING_LOG"
}

#=============================================================================
# Function: analyze_temporal_patterns
# Description: Analyze timing patterns in observations
#=============================================================================
analyze_temporal_patterns() {
    local observation_id="$1"
    local observation_file="${OBSERVATIONS_DIR}/${observation_id}.json"
    local observation_time=$(cat "$observation_file" | jq -r '.timestamp')
    
    # Check for patterns in timing (e.g., conflicts after deployments)
    local recent_observations=$(find "$OBSERVATIONS_DIR" -name "*.json" -newer <(date -d "1 hour ago") | head -10)
    
    if [[ $(echo "$recent_observations" | wc -l) -gt 5 ]]; then
        warning "🕒 High observation frequency detected - possible system instability"
        record_observation "high_frequency_pattern" "temporal_analysis" \
            '{"observation_count": '$(echo "$recent_observations" | wc -l)', "time_window": "1_hour"}' \
            ""
    fi
}

#=============================================================================
# Function: analyze_resolution_patterns
# Description: Track which solutions work for which problems
#=============================================================================
analyze_resolution_patterns() {
    local observation_id="$1"
    local observation_file="${OBSERVATIONS_DIR}/${observation_id}.json"
    local observation_type=$(cat "$observation_file" | jq -r '.observation_type')
    
    # If this is a solution observation, look for related problems
    if [[ "$observation_type" == *"solution"* || "$observation_type" == *"resolved"* ]]; then
        info "🎯 Analyzing solution effectiveness for: $observation_id"
        
        # Find recent problem observations that might be related
        local recent_problems=$(find "$OBSERVATIONS_DIR" -name "*.json" -newer <(date -d "30 minutes ago") \
            -exec grep -l "conflict\|error\|failure" {} \;)
        
        if [[ -n "$recent_problems" ]]; then
            echo "$recent_problems" | while read -r problem_file; do
                local problem_id=$(basename "$problem_file" .json)
                create_relationship "$problem_id" "$observation_id" "resolved_by" "0.8" \
                    '{"resolution_time": "30_minutes", "method": "automatic"}'
            done
        fi
    fi
}

##############################################################################
#                             MEMORY PRUNING                                #
##############################################################################

#=============================================================================
# Function: prune_memory
# Description: Clean old, irrelevant data while preserving valuable patterns
#
# Parameters:
#   $1 - retention_days (default: 30)
#   $2 - min_confidence (default: 0.3)
#=============================================================================
prune_memory() {
    local retention_days="${1:-30}"
    local min_confidence="${2:-0.3}"
    local timestamp=$(date -Iseconds)
    local pruned_count=0
    
    info "🧹 Starting memory pruning (retention: ${retention_days} days, min_confidence: ${min_confidence})"
    
    # Prune old observations with low confidence
    info "Pruning observations..."
    find "$OBSERVATIONS_DIR" -name "*.json" -mtime "+$retention_days" | while read -r obs_file; do
        local confidence=$(cat "$obs_file" | jq -r '.confidence // 0')
        if (( $(echo "$confidence < $min_confidence" | bc -l) )); then
            local obs_id=$(basename "$obs_file" .json)
            rm "$obs_file"
            echo "$timestamp|pruned|observation|$obs_id|confidence:$confidence" >> "$PRUNING_LOG"
            ((pruned_count++))
        fi
    done
    
    # Prune entities with no recent activity
    info "Pruning inactive entities..."
    find "$ENTITIES_DIR" -name "*.json" -mtime "+$retention_days" | while read -r entity_file; do
        local last_seen=$(cat "$entity_file" | jq -r '.last_seen')
        local entity_id=$(cat "$entity_file" | jq -r '.entity_id')
        local observation_count=$(cat "$entity_file" | jq -r '.observation_count')
        
        # Keep entities with high observation counts even if old
        if [[ $observation_count -lt 3 ]]; then
            rm "$entity_file"
            echo "$timestamp|pruned|entity|$entity_id|observations:$observation_count" >> "$PRUNING_LOG"
            ((pruned_count++))
        fi
    done
    
    # Prune weak relationships
    info "Pruning weak relationships..."
    find "$RELATIONSHIPS_DIR" -name "*.json" | while read -r rel_file; do
        local strength=$(cat "$rel_file" | jq -r '.strength')
        local observation_count=$(cat "$rel_file" | jq -r '.observation_count')
        local rel_id=$(cat "$rel_file" | jq -r '.relationship_id')
        
        # Remove relationships with low strength and few observations
        if (( $(echo "$strength < 0.2" | bc -l) )) && [[ $observation_count -lt 2 ]]; then
            rm "$rel_file"
            echo "$timestamp|pruned|relationship|$rel_id|strength:$strength" >> "$PRUNING_LOG"
            ((pruned_count++))
        fi
    done
    
    # Update metrics
    update_memory_metrics "pruning_completed" "$pruned_count"
    
    success "🧹 Memory pruning completed. Removed $pruned_count items."
    echo "$timestamp|pruning_session|completed|removed:$pruned_count|retention:${retention_days}d" >> "$PRUNING_LOG"
    
    return 0
}

##############################################################################
#                          PREDICTIVE ANALYTICS                             #
##############################################################################

#=============================================================================
# Function: generate_predictions
# Description: Generate predictions based on patterns and relationships
#=============================================================================
generate_predictions() {
    local context="${1:-general}"
    local timestamp=$(date -Iseconds)
    
    info "🔮 Generating predictions for context: $context"
    
    local predictions_file="${INSIGHTS_DIR}/predictions_$(date +%Y%m%d_%H%M).json"
    
    # Initialize predictions structure
    cat > "$predictions_file" << EOF
{
    "generated_at": "$timestamp",
    "context": "$context",
    "predictions": [],
    "confidence_metrics": {},
    "recommendations": []
}
EOF
    
    # Analyze patterns for predictions
    analyze_deployment_patterns "$predictions_file"
    analyze_conflict_patterns "$predictions_file"
    analyze_resource_patterns "$predictions_file"
    
    # Generate actionable recommendations
    generate_actionable_recommendations "$predictions_file"
    
    success "🔮 Predictions generated: $predictions_file"
    
    # Display key predictions
    display_key_predictions "$predictions_file"
}

#=============================================================================
# Function: analyze_deployment_patterns
# Description: Predict deployment success/failure based on historical patterns
#=============================================================================
analyze_deployment_patterns() {
    local predictions_file="$1"
    
    # Find deployment-related patterns
    local deployment_patterns=$(find "$PATTERNS_DIR" -name "*deployment*" -o -name "*setup*")
    
    if [[ -n "$deployment_patterns" ]]; then
        local success_rate=$(echo "$deployment_patterns" | xargs cat | jq '[.resolution_success_rate] | add / length' 2>/dev/null || echo "0.5")
        
        # Add prediction to file
        local prediction=$(cat "$predictions_file" | jq --argjson rate "$success_rate" '
            .predictions += [{
                "type": "deployment_success",
                "probability": $rate,
                "context": "Based on historical deployment patterns",
                "confidence": 0.7
            }]
        ')
        echo "$prediction" > "$predictions_file"
        
        info "📊 Deployment success prediction: $(echo "scale=0; $success_rate * 100" | bc)%"
    fi
}

#=============================================================================
# Function: analyze_conflict_patterns
# Description: Predict potential conflicts based on service patterns
#=============================================================================
analyze_conflict_patterns() {
    local predictions_file="$1"
    
    # Find conflict patterns
    local conflict_patterns=$(find "$PATTERNS_DIR" -name "*conflict*" -o -name "*port*")
    
    if [[ -n "$conflict_patterns" ]]; then
        local high_risk_services=()
        
        echo "$conflict_patterns" | while read -r pattern_file; do
            local service_context=$(cat "$pattern_file" | jq -r '.context')
            local occurrence_count=$(cat "$pattern_file" | jq -r '.occurrence_count')
            
            if [[ $occurrence_count -gt 3 ]]; then
                high_risk_services+=("$service_context")
            fi
        done
        
        if [[ ${#high_risk_services[@]} -gt 0 ]]; then
            info "⚠️  High-risk services for conflicts: ${high_risk_services[*]}"
            
            # Add conflict prediction to file
            local prediction=$(cat "$predictions_file" | jq --argjson services "$(printf '%s\n' "${high_risk_services[@]}" | jq -R . | jq -s .)" '
                .predictions += [{
                    "type": "service_conflicts",
                    "high_risk_services": $services,
                    "probability": 0.6,
                    "context": "Based on historical conflict patterns",
                    "confidence": 0.8
                }]
            ')
            echo "$prediction" > "$predictions_file"
        fi
    fi
}

#=============================================================================
# Function: analyze_resource_patterns
# Description: Predict resource utilization and bottlenecks
#=============================================================================
analyze_resource_patterns() {
    local predictions_file="$1"
    
    # Analyze current resource state
    local disk_usage=$(df /home/joe/usenet | awk 'NR==2 {print $5}' | sed 's/%//')
    local memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    local container_count=$(docker ps --format "{{.Names}}" | wc -l)
    
    # Generate resource predictions
    local disk_trend="stable"
    [[ $disk_usage -gt 80 ]] && disk_trend="critical"
    [[ $disk_usage -gt 90 ]] && disk_trend="emergency"
    
    local prediction=$(cat "$predictions_file" | jq --argjson disk "$disk_usage" --argjson memory "$memory_usage" --argjson containers "$container_count" --arg trend "$disk_trend" '
        .predictions += [{
            "type": "resource_utilization",
            "current_disk_usage": $disk,
            "current_memory_usage": $memory,
            "current_containers": $containers,
            "disk_trend": $trend,
            "context": "Current resource analysis",
            "confidence": 0.9
        }]
    ')
    echo "$prediction" > "$predictions_file"
    
    info "📊 Resource utilization - Disk: ${disk_usage}%, Memory: ${memory_usage}%, Containers: $container_count"
}

#=============================================================================
# Function: generate_actionable_recommendations
# Description: Generate specific actionable recommendations
#=============================================================================
generate_actionable_recommendations() {
    local predictions_file="$1"
    
    # Analyze predictions and generate recommendations
    local recommendations=()
    
    # Check for high conflict predictions
    local conflict_prediction=$(cat "$predictions_file" | jq -r '.predictions[] | select(.type == "service_conflicts") | .probability')
    if [[ -n "$conflict_prediction" ]] && (( $(echo "$conflict_prediction > 0.5" | bc -l) )); then
        recommendations+=("Pre-stop conflicting services before deployment")
        recommendations+=("Implement port validation checks")
    fi
    
    # Check for resource concerns
    local disk_usage=$(cat "$predictions_file" | jq -r '.predictions[] | select(.type == "resource_utilization") | .current_disk_usage')
    if [[ -n "$disk_usage" ]] && [[ $disk_usage -gt 80 ]]; then
        recommendations+=("Clean up old Docker images and volumes")
        recommendations+=("Consider expanding storage capacity")
    fi
    
    # Add recommendations to file
    local updated_predictions=$(cat "$predictions_file" | jq --argjson recs "$(printf '%s\n' "${recommendations[@]}" | jq -R . | jq -s .)" '
        .recommendations = $recs
    ')
    echo "$updated_predictions" > "$predictions_file"
}

#=============================================================================
# Function: display_key_predictions
# Description: Display human-readable prediction summary
#=============================================================================
display_key_predictions() {
    local predictions_file="$1"
    
    print "\n🔮 KEY PREDICTIONS & RECOMMENDATIONS"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Display predictions
    cat "$predictions_file" | jq -r '.predictions[] | "  🎯 \(.type): \(.context) (confidence: \(.confidence * 100 | floor)%)"'
    
    print "\n💡 RECOMMENDATIONS:"
    cat "$predictions_file" | jq -r '.recommendations[]? | "  • \(.)"'
    
    print "\n📊 Generated at: $(cat "$predictions_file" | jq -r '.generated_at')"
}

##############################################################################
#                             METRICS & MONITORING                          #
##############################################################################

#=============================================================================
# Function: update_memory_metrics
# Description: Update memory system performance metrics
#=============================================================================
update_memory_metrics() {
    local action="$1"
    local category="$2"
    local timestamp=$(date -Iseconds)
    
    # Initialize metrics file if it doesn't exist
    if [[ ! -f "$MEMORY_METRICS" ]]; then
        cat > "$MEMORY_METRICS" << EOF
{
    "initialized_at": "$timestamp",
    "last_updated": "$timestamp",
    "total_entities": 0,
    "total_observations": 0,
    "total_relationships": 0,
    "total_patterns": 0,
    "actions": {},
    "categories": {}
}
EOF
    fi
    
    # Update metrics
    local updated_metrics=$(cat "$MEMORY_METRICS" | jq --arg timestamp "$timestamp" --arg action "$action" --arg category "$category" '
        .last_updated = $timestamp |
        .total_entities = (if $action == "entity_created" then .total_entities + 1 else .total_entities end) |
        .total_observations = (if $action == "observation_recorded" then .total_observations + 1 else .total_observations end) |
        .actions[$action] = ((.actions[$action] // 0) + 1) |
        .categories[$category] = ((.categories[$category] // 0) + 1)
    ')
    
    echo "$updated_metrics" > "$MEMORY_METRICS"
}

#=============================================================================
# Function: display_memory_stats
# Description: Display comprehensive memory system statistics
#=============================================================================
display_memory_stats() {
    if [[ ! -f "$MEMORY_METRICS" ]]; then
        warning "No memory metrics available"
        return 1
    fi
    
    print "\n📊 MEMORY SYSTEM STATISTICS"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local metrics_data=$(cat "$MEMORY_METRICS")
    
    # Display totals
    print "📈 Total Entities:      $(echo "$metrics_data" | jq -r '.total_entities')"
    print "📝 Total Observations:  $(echo "$metrics_data" | jq -r '.total_observations')"  
    print "🔗 Total Relationships: $(find "$RELATIONSHIPS_DIR" -name "*.json" | wc -l)"
    print "🎯 Total Patterns:      $(find "$PATTERNS_DIR" -name "*.json" | wc -l)"
    
    # Display storage usage
    local storage_usage=$(du -sh "$MEMORY_BASE_DIR" | cut -f1)
    print "💾 Storage Usage:       $storage_usage"
    
    # Display recent activity
    print "\n🕒 Recent Activity:"
    tail -5 "$LEARNING_LOG" 2>/dev/null | while IFS='|' read -r timestamp action type context detail; do
        [[ -n "$timestamp" ]] && print "   $(date -d "$timestamp" '+%H:%M:%S') - $action: $type ($context)"
    done
    
    # Display top categories
    print "\n📊 Top Categories:"
    echo "$metrics_data" | jq -r '.categories | to_entries | sort_by(.value) | reverse | limit(5;.[]) | "   \(.key): \(.value)"'
    
    print "\n📅 Last Updated: $(echo "$metrics_data" | jq -r '.last_updated')"
}

##############################################################################
#                              INTEGRATION API                              #
##############################################################################

#=============================================================================
# Function: integrate_with_orchestrator
# Description: Integration hooks for intelligent orchestrator
#=============================================================================
integrate_with_orchestrator() {
    local event_type="$1"
    local event_data="$2"
    
    case "$event_type" in
        "conflict_detected")
            record_observation "port_conflict" "docker_deployment" "$event_data" ""
            ;;
        "solution_applied")
            record_observation "solution_applied" "auto_fix" "$event_data" ""
            ;;
        "deployment_started")
            record_observation "deployment_started" "docker_orchestration" "$event_data" ""
            ;;
        "deployment_completed")
            record_observation "deployment_completed" "docker_orchestration" "$event_data" ""
            ;;
        *)
            record_observation "general_event" "system" "$event_data" ""
            ;;
    esac
}

#=============================================================================
# Function: get_learning_insights
# Description: Get actionable insights for current situation
#=============================================================================
get_learning_insights() {
    local context="$1"
    
    info "🧠 Retrieving learning insights for: $context"
    
    # Generate fresh predictions
    generate_predictions "$context"
    
    # Find relevant patterns
    local relevant_patterns=$(find "$PATTERNS_DIR" -name "*${context}*" -o -name "*docker*" | head -5)
    
    if [[ -n "$relevant_patterns" ]]; then
        print "\n📚 Relevant Learning Patterns:"
        echo "$relevant_patterns" | while read -r pattern_file; do
            local pattern_id=$(cat "$pattern_file" | jq -r '.pattern_id')
            local confidence=$(cat "$pattern_file" | jq -r '.confidence')
            local occurrences=$(cat "$pattern_file" | jq -r '.occurrence_count')
            
            print "   🎯 $pattern_id (confidence: $(echo "scale=0; $confidence * 100" | bc)%, occurrences: $occurrences)"
        done
    fi
    
    # Return latest predictions file
    local latest_predictions=$(find "$INSIGHTS_DIR" -name "predictions_*.json" | sort | tail -1)
    [[ -f "$latest_predictions" ]] && echo "$latest_predictions"
}

##############################################################################
#                                MAIN CLI                                   #
##############################################################################

#=============================================================================
# Function: main
# Description: Main CLI interface for memory management
#=============================================================================
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            info "🚀 Initializing memory management system..."
            mkdir -p "$MEMORY_BASE_DIR" "$ENTITIES_DIR" "$OBSERVATIONS_DIR" "$RELATIONSHIPS_DIR" "$PATTERNS_DIR" "$INSIGHTS_DIR"
            update_memory_metrics "system_initialized" "setup"
            success "Memory management system initialized"
            ;;
        "stats")
            display_memory_stats
            ;;
        "prune")
            prune_memory "${2:-30}" "${3:-0.3}"
            ;;
        "predict")
            generate_predictions "${2:-general}"
            ;;
        "insights")
            get_learning_insights "${2:-docker}"
            ;;
        "record")
            record_observation "$2" "$3" "$4" "$5"
            ;;
        "entity")
            case "$2" in
                "create") create_entity "$3" "$4" "$5" ;;
                "get") get_entity "$3" "$4" "${5:-false}" ;;
                "update") update_entity "$3" "$4" "$5" ;;
                *) error "Usage: $0 entity {create|get|update} <type> <name> [data]" ;;
            esac
            ;;
        "help"|*)
            cat << EOF
Memory Management System - Comprehensive MCP-Powered Learning

USAGE:
    $0 <command> [options]

COMMANDS:
    init                     Initialize memory management system
    stats                    Display memory system statistics
    prune [days] [confidence] Prune old data (default: 30 days, 0.3 confidence)
    predict [context]        Generate predictions for context
    insights [context]       Get learning insights for context
    record <type> <context> <data> [entities]  Record observation
    entity create <type> <name> <data>         Create entity
    entity get <type> <name> [expand]          Get entity data
    entity update <type> <name> <data>         Update entity

EXAMPLES:
    $0 init                  # Initialize system
    $0 record conflict_detected docker_deployment '{"port": 5055, "service": "overseerr"}'
    $0 entity create docker_service overseerr '{"port": 5055, "category": "requests"}'
    $0 predict docker_deployment
    $0 prune 7 0.5          # Aggressive pruning (7 days, 0.5 confidence)
    $0 stats                # Show system statistics

EOF
            ;;
    esac
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi