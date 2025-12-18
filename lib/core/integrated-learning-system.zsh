#!/usr/bin/env zsh
##############################################################################
# File: ./lib/core/integrated-learning-system.zsh
# Project: Usenet Media Stack - Integrated Learning System
# Description: Unified MCP-powered learning orchestration with full integration
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-28
# Version: 1.0.0
# License: MIT
#
# This module provides the unified interface that combines intelligent
# orchestration with comprehensive memory management to create a fully
# self-learning Docker media stack system.
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

# Load subsystems
source "${SCRIPT_DIR}/intelligent-orchestrator.zsh" || {
    print -u2 "ERROR: Cannot load intelligent-orchestrator.zsh"
    exit 1
}

source "${SCRIPT_DIR}/memory-manager.zsh" || {
    print -u2 "ERROR: Cannot load memory-manager.zsh"
    exit 1
}

# Integrated System Configuration
LEARNING_SYSTEM_DIR="/home/joe/usenet/.learning_system"
INTEGRATION_LOG="${LEARNING_SYSTEM_DIR}/integration.log"
SESSION_LOG="${LEARNING_SYSTEM_DIR}/sessions.log"
PERFORMANCE_LOG="${LEARNING_SYSTEM_DIR}/performance.log"

# Ensure directory structure
mkdir -p "$LEARNING_SYSTEM_DIR"

##############################################################################
#                          INTEGRATED ORCHESTRATION                         #
##############################################################################

#=============================================================================
# Function: smart_deployment_with_learning
# Description: Orchestrate deployment with full learning integration
#
# This function represents the pinnacle of the system - it combines intelligent
# conflict detection, memory-based pattern recognition, predictive analytics,
# and automated learning from every action taken.
#=============================================================================
smart_deployment_with_learning() {
    local deployment_context="${1:-full_stack}"
    local auto_fix="${2:-false}"
    local session_id="deploy_$(date +%s%N)"
    local start_time=$(date +%s)
    
    info "🚀 Initiating smart deployment with integrated learning"
    info "📊 Session ID: $session_id"
    
    # Phase 0: Initialize session in memory system
    record_observation "deployment_session_started" "$deployment_context" \
        "{\"session_id\": \"$session_id\", \"auto_fix\": \"$auto_fix\", \"timestamp\": \"$(date -Iseconds)\"}" \
        ""
    
    # Phase 1: Pre-deployment Intelligence Gathering
    info "🧠 Phase 1: Pre-deployment Intelligence Analysis"
    
    # Get predictions for this deployment
    local predictions_file=$(get_learning_insights "$deployment_context")
    local deployment_confidence=0.5
    
    if [[ -f "$predictions_file" ]]; then
        deployment_confidence=$(cat "$predictions_file" | jq -r '.predictions[] | select(.type == "deployment_success") | .probability // 0.5')
        info "📊 Deployment confidence based on historical patterns: $(echo "scale=0; $deployment_confidence * 100" | bc)%"
        
        # Record prediction as observation
        record_observation "deployment_prediction" "$deployment_context" \
            "{\"confidence\": $deployment_confidence, \"predictions_file\": \"$predictions_file\"}" \
            ""
    fi
    
    # Phase 2: Enhanced Diagnostic Analysis with Memory Integration
    info "🔍 Phase 2: Enhanced Diagnostic Analysis"
    
    local diagnostic_result
    if diagnose_docker_state; then
        diagnostic_result="clean"
        record_observation "pre_deployment_analysis" "$deployment_context" \
            "{\"result\": \"clean\", \"conflicts_detected\": false}" \
            ""
    else
        diagnostic_result="conflicts_detected"
        record_observation "pre_deployment_analysis" "$deployment_context" \
            "{\"result\": \"conflicts_detected\", \"conflicts_detected\": true}" \
            ""
        
        # Create entities for detected conflicts
        create_conflict_entities_from_analysis
    fi
    
    # Phase 3: Memory-Informed Decision Making
    info "🎯 Phase 3: Memory-Informed Decision Making"
    
    local resolution_strategy=$(determine_resolution_strategy "$diagnostic_result" "$deployment_confidence")
    info "🧭 Resolution strategy: $resolution_strategy"
    
    # Phase 4: Intelligent Auto-Fix (if enabled and recommended)
    if [[ "$auto_fix" == "true" && "$resolution_strategy" == "auto_fix_recommended" ]]; then
        info "🤖 Phase 4: Applying Intelligent Auto-Fix"
        
        if intelligent_auto_fix; then
            record_observation "auto_fix_applied" "$deployment_context" \
                "{\"result\": \"success\", \"strategy\": \"$resolution_strategy\"}" \
                ""
            create_relationship "deployment_session_$session_id" "auto_fix_success" "resolved_by" "0.9" \
                "{\"method\": \"intelligent_auto_fix\", \"session\": \"$session_id\"}"
        else
            record_observation "auto_fix_failed" "$deployment_context" \
                "{\"result\": \"failure\", \"strategy\": \"$resolution_strategy\"}" \
                ""
        fi
    fi
    
    # Phase 5: Final Deployment Execution with Learning
    info "🚀 Phase 5: Final Deployment Execution"
    
    local deployment_start=$(date +%s)
    local deployment_result
    
    if execute_deployment_with_monitoring "$session_id"; then
        deployment_result="success"
        local deployment_time=$(($(date +%s) - deployment_start))
        
        record_observation "deployment_completed" "$deployment_context" \
            "{\"result\": \"success\", \"duration_seconds\": $deployment_time, \"session_id\": \"$session_id\"}" \
            "deployment_session_$session_id"
        
        success "✅ Deployment completed successfully in ${deployment_time}s"
    else
        deployment_result="failure"
        local deployment_time=$(($(date +%s) - deployment_start))
        
        record_observation "deployment_failed" "$deployment_context" \
            "{\"result\": \"failure\", \"duration_seconds\": $deployment_time, \"session_id\": \"$session_id\"}" \
            "deployment_session_$session_id"
        
        error "❌ Deployment failed after ${deployment_time}s"
    fi
    
    # Phase 6: Post-Deployment Learning and Analysis
    info "📚 Phase 6: Post-Deployment Learning"
    
    analyze_deployment_session "$session_id" "$deployment_result" "$deployment_confidence"
    
    # Phase 7: Generate Session Insights and Update Knowledge Base
    local total_time=$(($(date +%s) - start_time))
    generate_session_summary "$session_id" "$deployment_result" "$total_time"
    
    # Learn from this session
    learn_from_session
    
    # Return appropriate exit code
    [[ "$deployment_result" == "success" ]] && return 0 || return 1
}

#=============================================================================
# Function: determine_resolution_strategy
# Description: Use memory and predictions to determine best resolution approach
#=============================================================================
determine_resolution_strategy() {
    local diagnostic_result="$1"
    local deployment_confidence="$2"
    
    # Check historical patterns for similar situations
    local similar_patterns=$(find "${PATTERNS_DIR}" -name "*conflict*" -o -name "*deployment*" | head -3)
    local auto_fix_success_rate=0.5
    
    if [[ -n "$similar_patterns" ]]; then
        auto_fix_success_rate=$(echo "$similar_patterns" | xargs cat | jq '[.resolution_success_rate] | add / length' 2>/dev/null || echo "0.5")
    fi
    
    # Decision logic based on confidence and historical success
    if [[ "$diagnostic_result" == "clean" ]]; then
        echo "proceed_immediately"
    elif (( $(echo "$deployment_confidence > 0.7" | bc -l) )) && (( $(echo "$auto_fix_success_rate > 0.6" | bc -l) )); then
        echo "auto_fix_recommended"
    elif (( $(echo "$deployment_confidence > 0.4" | bc -l) )); then
        echo "manual_review_recommended"
    else
        echo "abort_recommended"
    fi
}

#=============================================================================
# Function: create_conflict_entities_from_analysis
# Description: Create entities for detected conflicts for future reference
#=============================================================================
create_conflict_entities_from_analysis() {
    info "📊 Creating conflict entities from analysis"
    
    # Parse recent analysis for conflicts
    if [[ -f "${INTELLIGENCE_DIR}/patterns.db" ]]; then
        # Get recent conflicts from memory
        local recent_conflicts=$(tail -10 "${INTELLIGENCE_DIR}/patterns.db" | grep "port_conflict")
        
        echo "$recent_conflicts" | while IFS='|' read -r timestamp type port service category action; do
            if [[ -n "$port" && -n "$service" ]]; then
                # Create conflict entity
                create_entity "port_conflict" "${port}_${service}" \
                    "{\"port\": $port, \"service\": \"$service\", \"category\": \"$category\", \"detected_at\": \"$timestamp\"}"
                
                # Create service entity if not exists
                create_entity "docker_service" "$service" \
                    "{\"name\": \"$service\", \"port\": $port, \"category\": \"$category\", \"status\": \"conflicted\"}"
                
                # Create relationship
                create_relationship "docker_service_$service" "port_conflict_${port}_${service}" "experiences" "0.8" \
                    "{\"conflict_type\": \"port_binding\", \"detected_at\": \"$timestamp\"}"
            fi
        done
    fi
}

#=============================================================================
# Function: execute_deployment_with_monitoring
# Description: Execute deployment with real-time monitoring and learning
#=============================================================================
execute_deployment_with_monitoring() {
    local session_id="$1"
    
    info "🚀 Executing deployment with real-time monitoring"
    
    # Pre-deployment state capture
    local pre_containers=$(docker ps --format "{{.Names}}" | wc -l)
    local pre_networks=$(docker network ls | wc -l)
    
    # Execute the actual deployment
    local deployment_command="docker compose up -d"
    info "🔧 Running: $deployment_command"
    
    # Monitor deployment with timeout
    if timeout 300 docker compose up -d 2>&1 | tee "${LEARNING_SYSTEM_DIR}/deployment_${session_id}.log"; then
        # Post-deployment state capture
        local post_containers=$(docker ps --format "{{.Names}}" | wc -l)
        local post_networks=$(docker network ls | wc -l)
        
        # Record deployment metrics
        record_observation "deployment_metrics" "docker_compose" \
            "{\"containers_before\": $pre_containers, \"containers_after\": $post_containers, \"networks_before\": $pre_networks, \"networks_after\": $post_networks}" \
            "deployment_session_$session_id"
        
        # Verify deployment health
        if verify_deployment_health "$session_id"; then
            return 0
        else
            warning "Deployment completed but health check failed"
            return 1
        fi
    else
        error "Deployment timed out or failed"
        record_observation "deployment_timeout" "docker_compose" \
            "{\"timeout_seconds\": 300, \"session_id\": \"$session_id\"}" \
            "deployment_session_$session_id"
        return 1
    fi
}

#=============================================================================
# Function: verify_deployment_health
# Description: Comprehensive post-deployment health verification
#=============================================================================
verify_deployment_health() {
    local session_id="$1"
    local health_score=0
    local total_checks=0
    
    info "🏥 Verifying deployment health"
    
    # Check 1: Container Status
    local running_containers=$(docker ps --format "{{.Names}}" | wc -l)
    local expected_containers=19  # Based on our docker-compose
    
    if [[ $running_containers -ge $((expected_containers - 2)) ]]; then
        ((health_score++))
        info "✅ Container check passed ($running_containers/$expected_containers)"
    else
        warning "⚠️ Container check failed ($running_containers/$expected_containers)"
    fi
    ((total_checks++))
    
    # Check 2: Port Availability
    local port_conflicts=$(netstat -tln 2>/dev/null | grep -E ":5055|:32400|:8989|:7878" | wc -l)
    if [[ $port_conflicts -ge 3 ]]; then
        ((health_score++))
        info "✅ Key services responding on expected ports"
    else
        warning "⚠️ Some key services not responding"
    fi
    ((total_checks++))
    
    # Check 3: Docker Network Health
    local network_errors=$(docker network ls | grep -c "bridge\|host" || echo "0")
    if [[ $network_errors -ge 2 ]]; then
        ((health_score++))
        info "✅ Docker networking healthy"
    else
        warning "⚠️ Docker networking issues detected"
    fi
    ((total_checks++))
    
    # Calculate health percentage
    local health_percentage=$(echo "scale=2; $health_score / $total_checks * 100" | bc)
    
    # Record health metrics
    record_observation "deployment_health_check" "verification" \
        "{\"health_score\": $health_score, \"total_checks\": $total_checks, \"health_percentage\": $health_percentage}" \
        "deployment_session_$session_id"
    
    info "🏥 Health check completed: $health_score/$total_checks ($health_percentage%)"
    
    # Consider deployment healthy if ≥70% of checks pass
    [[ $(echo "$health_percentage >= 70" | bc) -eq 1 ]]
}

#=============================================================================
# Function: analyze_deployment_session
# Description: Comprehensive analysis of deployment session for learning
#=============================================================================
analyze_deployment_session() {
    local session_id="$1"
    local deployment_result="$2"
    local predicted_confidence="$3"
    
    info "📊 Analyzing deployment session: $session_id"
    
    # Calculate prediction accuracy
    local actual_success=$([ "$deployment_result" == "success" ] && echo "1.0" || echo "0.0")
    local prediction_error=$(echo "scale=3; $actual_success - $predicted_confidence" | bc | sed 's/^-//')
    
    # Update prediction accuracy patterns
    record_observation "prediction_accuracy" "analysis" \
        "{\"predicted_confidence\": $predicted_confidence, \"actual_success\": $actual_success, \"prediction_error\": $prediction_error}" \
        "deployment_session_$session_id"
    
    # Learn from specific outcomes
    if [[ "$deployment_result" == "success" ]]; then
        # Reinforce successful patterns
        strengthen_successful_patterns "$session_id"
    else
        # Analyze failure patterns
        analyze_failure_patterns "$session_id"
    fi
    
    # Update deployment entity with results
    update_entity "deployment_session" "$session_id" \
        "{\"result\": \"$deployment_result\", \"predicted_confidence\": $predicted_confidence, \"actual_success\": $actual_success}"
    
    info "🎯 Session analysis completed - Prediction error: $prediction_error"
}

#=============================================================================
# Function: strengthen_successful_patterns
# Description: Reinforce patterns that led to successful deployments
#=============================================================================
strengthen_successful_patterns() {
    local session_id="$1"
    
    # Find patterns that contributed to success
    local session_observations=$(find "$OBSERVATIONS_DIR" -name "*.json" -newer <(date -d "1 hour ago") | xargs grep -l "$session_id")
    
    echo "$session_observations" | while read -r obs_file; do
        local obs_data=$(cat "$obs_file")
        local obs_type=$(echo "$obs_data" | jq -r '.observation_type')
        
        # Find related patterns and increase their confidence
        local related_patterns=$(find "$PATTERNS_DIR" -name "*${obs_type}*")
        echo "$related_patterns" | while read -r pattern_file; do
            if [[ -f "$pattern_file" ]]; then
                # Increase pattern confidence slightly
                local updated_pattern=$(cat "$pattern_file" | jq '
                    .confidence = ((.confidence + 0.1) | if . > 1.0 then 1.0 else . end) |
                    .resolution_success_rate = ((.resolution_success_rate + 0.1) | if . > 1.0 then 1.0 else . end)
                ')
                echo "$updated_pattern" > "$pattern_file"
            fi
        done
    done
    
    info "💪 Strengthened patterns that contributed to successful deployment"
}

#=============================================================================
# Function: analyze_failure_patterns
# Description: Analyze patterns that led to deployment failures
#=============================================================================
analyze_failure_patterns() {
    local session_id="$1"
    
    info "🔍 Analyzing failure patterns for session: $session_id"
    
    # Record failure analysis
    record_observation "deployment_failure_analysis" "pattern_analysis" \
        "{\"session_id\": \"$session_id\", \"analysis_timestamp\": \"$(date -Iseconds)\"}" \
        "deployment_session_$session_id"
    
    # Look for common failure indicators
    if [[ -f "${LEARNING_SYSTEM_DIR}/deployment_${session_id}.log" ]]; then
        local log_file="${LEARNING_SYSTEM_DIR}/deployment_${session_id}.log"
        
        # Analyze common error patterns
        if grep -q "port.*already in use" "$log_file"; then
            record_observation "failure_cause_identified" "port_conflict" \
                "{\"cause\": \"port_conflict\", \"session_id\": \"$session_id\"}" \
                "deployment_session_$session_id"
        elif grep -q "no space left" "$log_file"; then
            record_observation "failure_cause_identified" "disk_space" \
                "{\"cause\": \"insufficient_disk_space\", \"session_id\": \"$session_id\"}" \
                "deployment_session_$session_id"
        elif grep -q "network.*error" "$log_file"; then
            record_observation "failure_cause_identified" "network_error" \
                "{\"cause\": \"network_configuration\", \"session_id\": \"$session_id\"}" \
                "deployment_session_$session_id"
        fi
    fi
}

#=============================================================================
# Function: generate_session_summary
# Description: Generate comprehensive session summary with insights
#=============================================================================
generate_session_summary() {
    local session_id="$1"
    local deployment_result="$2"
    local total_time="$3"
    local timestamp=$(date -Iseconds)
    
    local summary_file="${LEARNING_SYSTEM_DIR}/session_summary_${session_id}.json"
    
    # Gather session statistics
    local session_observations=$(find "$OBSERVATIONS_DIR" -name "*.json" -exec grep -l "$session_id" {} \; | wc -l)
    local entities_created=$(grep "$session_id" "$LEARNING_LOG" | grep -c "entity_created" || echo "0")
    local relationships_created=$(grep "$session_id" "$LEARNING_LOG" | grep -c "relationship_created" || echo "0")
    
    # Create comprehensive session summary
    cat > "$summary_file" << EOF
{
    "session_id": "$session_id",
    "timestamp": "$timestamp",
    "deployment_result": "$deployment_result",
    "total_duration_seconds": $total_time,
    "statistics": {
        "observations_recorded": $session_observations,
        "entities_created": $entities_created,
        "relationships_created": $relationships_created
    },
    "performance_metrics": {
        "deployment_efficiency": $(echo "scale=2; 1 / ($total_time / 60.0)" | bc),
        "learning_intensity": $(echo "scale=2; $session_observations / ($total_time / 60.0)" | bc)
    },
    "learning_outcomes": {
        "patterns_updated": $(find "$PATTERNS_DIR" -newer <(date -d "1 hour ago") | wc -l),
        "knowledge_growth": "$(calculate_knowledge_growth)"
    }
}
EOF
    
    # Log session summary
    echo "$timestamp|session_completed|$session_id|$deployment_result|duration:${total_time}s|observations:$session_observations" >> "$SESSION_LOG"
    
    success "📋 Session summary generated: $summary_file"
    
    # Display key insights
    display_session_insights "$summary_file"
}

#=============================================================================
# Function: calculate_knowledge_growth
# Description: Calculate knowledge base growth metrics
#=============================================================================
calculate_knowledge_growth() {
    local total_files=$(find "$MEMORY_BASE_DIR" -name "*.json" | wc -l)
    local total_size=$(du -sh "$MEMORY_BASE_DIR" | cut -f1)
    echo "files:$total_files,size:$total_size"
}

#=============================================================================
# Function: display_session_insights
# Description: Display human-readable session insights
#=============================================================================
display_session_insights() {
    local summary_file="$1"
    
    if [[ ! -f "$summary_file" ]]; then
        return 1
    fi
    
    local summary_data=$(cat "$summary_file")
    
    print "\n📊 SESSION INSIGHTS & LEARNING SUMMARY"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    print "🎯 Result: $(echo "$summary_data" | jq -r '.deployment_result | ascii_upcase')"
    print "⏱️  Duration: $(echo "$summary_data" | jq -r '.total_duration_seconds')s"
    print "📊 Observations: $(echo "$summary_data" | jq -r '.statistics.observations_recorded')"
    print "🧠 Entities Created: $(echo "$summary_data" | jq -r '.statistics.entities_created')"
    print "🔗 Relationships: $(echo "$summary_data" | jq -r '.statistics.relationships_created')"
    print "📈 Learning Intensity: $(echo "$summary_data" | jq -r '.performance_metrics.learning_intensity') obs/min"
    print "📚 Knowledge Growth: $(echo "$summary_data" | jq -r '.learning_outcomes.knowledge_growth')"
    
    print "\n💡 Key Learnings Applied This Session:"
    
    # Show recent insights
    local recent_insights=$(find "$INSIGHTS_DIR" -name "*.json" -newer <(date -d "1 hour ago") | head -1)
    if [[ -f "$recent_insights" ]]; then
        cat "$recent_insights" | jq -r '.recommendations[]? | "   • \(.)"' | head -3
    fi
    
    print "\n🔮 Next Session Recommendations:"
    print "   • $(get_next_session_recommendations)"
}

#=============================================================================
# Function: get_next_session_recommendations
# Description: Generate recommendations for future sessions
#=============================================================================
get_next_session_recommendations() {
    local recent_failures=$(grep "deployment_failed" "$SESSION_LOG" | tail -3 | wc -l)
    local recent_successes=$(grep "success" "$SESSION_LOG" | tail -5 | wc -l)
    
    if [[ $recent_failures -gt 1 ]]; then
        echo "Enable auto-fix mode to resolve recurring conflicts automatically"
    elif [[ $recent_successes -gt 3 ]]; then
        echo "Consider implementing advanced optimizations for faster deployments"
    else
        echo "Continue current learning approach - patterns stabilizing well"
    fi
}

##############################################################################
#                              MAIN CLI INTERFACE                          #
##############################################################################

#=============================================================================
# Function: main
# Description: Main CLI interface for integrated learning system
#=============================================================================
main() {
    local command="${1:-help}"
    
    case "$command" in
        "deploy"|"smart-deploy")
            smart_deployment_with_learning "${2:-full_stack}" "${3:-false}"
            ;;
        "auto-deploy")
            smart_deployment_with_learning "${2:-full_stack}" "true"
            ;;
        "analyze")
            if [[ -n "$2" ]]; then
                analyze_deployment_session "$2" "${3:-unknown}" "${4:-0.5}"
            else
                error "Usage: $0 analyze <session_id> [result] [confidence]"
            fi
            ;;
        "insights")
            get_learning_insights "${2:-docker}"
            ;;
        "memory")
            shift
            source "${SCRIPT_DIR}/memory-manager.zsh"
            main "$@"
            ;;
        "stats"|"status")
            display_memory_stats
            echo ""
            display_session_stats
            ;;
        "init")
            info "🚀 Initializing integrated learning system..."
            mkdir -p "$LEARNING_SYSTEM_DIR"
            source "${SCRIPT_DIR}/memory-manager.zsh"
            main "init"
            success "Integrated learning system initialized"
            ;;
        "help"|*)
            cat << EOF
Integrated Learning System - MCP-Powered Docker Orchestration with Memory

USAGE:
    $0 <command> [options]

COMMANDS:
    deploy [context] [auto_fix]    Smart deployment with learning (auto_fix: true/false)
    auto-deploy [context]          Smart deployment with auto-fix enabled
    analyze <session_id> [result]  Analyze specific deployment session
    insights [context]             Get learning insights for context
    memory <command>               Access memory management functions
    stats                          Display system and session statistics
    init                           Initialize integrated learning system

EXAMPLES:
    $0 deploy full_stack false     # Careful deployment with learning
    $0 auto-deploy                 # Automated deployment with learning
    $0 analyze deploy_1703123456   # Analyze specific session
    $0 insights docker_deployment  # Get deployment insights
    $0 memory stats                # Memory system statistics
    $0 stats                       # Overall system status

SMART DEPLOYMENT FEATURES:
    • Pre-deployment intelligence gathering and prediction
    • Memory-informed conflict resolution strategies
    • Real-time monitoring with pattern recognition
    • Comprehensive post-deployment learning and analysis
    • Automated knowledge base updates and pattern strengthening
    • Cross-session learning for continuous improvement

MEMORY MANAGEMENT:
    • Entity tracking (services, conflicts, solutions)
    • Observation recording (events, metrics, outcomes)
    • Relationship mapping (causes, resolves, dependencies)
    • Pattern recognition and predictive analytics
    • Intelligent pruning and knowledge optimization

EOF
            ;;
    esac
}

#=============================================================================
# Function: display_session_stats
# Description: Display session-level statistics
#=============================================================================
display_session_stats() {
    print "\n📈 SESSION STATISTICS"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ -f "$SESSION_LOG" ]]; then
        local total_sessions=$(wc -l < "$SESSION_LOG")
        local successful_sessions=$(grep -c "success" "$SESSION_LOG")
        local failed_sessions=$(grep -c "failed" "$SESSION_LOG")
        local success_rate=$(echo "scale=1; $successful_sessions * 100 / $total_sessions" | bc 2>/dev/null || echo "0")
        
        print "📊 Total Sessions:      $total_sessions"
        print "✅ Successful:          $successful_sessions"
        print "❌ Failed:              $failed_sessions"
        print "📈 Success Rate:        ${success_rate}%"
        
        # Recent activity
        print "\n🕒 Recent Sessions:"
        tail -3 "$SESSION_LOG" | while IFS='|' read -r timestamp status session_id result duration_info observations; do
            [[ -n "$timestamp" ]] && print "   $(date -d "$timestamp" '+%H:%M:%S') - $session_id: $result"
        done
    else
        print "   No session data available"
    fi
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
