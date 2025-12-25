#!/bin/bash
#
# FileBot Test Plan for TV Reorganization
# Generated: 2025-01-25
#
# IMPORTANT: This is a testing script. Run each section manually and verify results
# before proceeding to the next step.
#
# Prerequisites:
# - FileBot installed with valid license
# - Backup completed to swap_drive
# - Test directory created

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

TV_ROOT="/run/media/deck/Fast_4TB_5/TV"
TEST_DIR="/tmp/filebot_test"
LOG_DIR="/var/home/deck/Documents/Code/media-automation/filebot_logs"
BACKUP_DIR="/run/media/deck/swap_drive/TV_backup"

# Create log directory
mkdir -p "$LOG_DIR"

# =============================================================================
# PHASE 0: VERIFY PREREQUISITES
# =============================================================================

echo "=== Phase 0: Verifying Prerequisites ==="

# Check FileBot installation
if ! command -v filebot &> /dev/null; then
    echo "ERROR: FileBot not installed"
    echo "Install with: flatpak install -y flathub net.filebot.FileBot"
    exit 1
fi

# Check FileBot license
if ! filebot -script fn:sysinfo | grep -q "License"; then
    echo "WARNING: FileBot license not detected"
    echo "Purchase and activate license before proceeding"
fi

# Verify backup exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR: Backup directory not found at $BACKUP_DIR"
    echo "Ensure backup is complete before proceeding"
    exit 1
fi

echo "✓ Prerequisites verified"
echo ""

# =============================================================================
# PHASE 1: CREATE TEST SUBSET
# =============================================================================

echo "=== Phase 1: Creating Test Subset ==="

# Clean test directory if it exists
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Copy test samples (using rsync to preserve structure)
# Pattern 1: Standard releases (10 One Piece episodes)
rsync -av "$TV_ROOT/One.Piece.S12E44"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S13E10"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S17E57"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S21E155"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S07E05"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S13E55"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S18E26"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S21E94"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S19E021"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/One.Piece.S03E01"* "$TEST_DIR/" || true

# Pattern 2: Fansub tags (5 episodes)
rsync -av "$TV_ROOT/[Arid].SteinsGate.2011-S01E08"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/[LostYears].Bleach"* "$TEST_DIR/" | head -1 || true
rsync -av "$TV_ROOT/[smol].Monogatari-S04E03"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/[Sokudo]_Goblin_Slayer"* "$TEST_DIR/" | head -1 || true
rsync -av "$TV_ROOT/[Yameii].Kaiji"* "$TEST_DIR/" | head -1 || true

# Pattern 3: Western releases (10 episodes)
rsync -av "$TV_ROOT/Seinfeld.S09E16"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Gravity.Falls.S01E06"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Its.Always.Sunny.in.Philadelphia.S10E05"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Doctor.Who.2005.S03E11"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/The.Bear.S03E06"* "$TEST_DIR/" || true

# Pattern 4: Classic Doctor Who (3 episodes)
rsync -av "$TV_ROOT/Doctor.Who.S07E20"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Doctor.Who.S20E10"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Doctor.Who.1963.S23E10"* "$TEST_DIR/" || true

# Pattern 5: Anime with various naming (7 episodes)
rsync -av "$TV_ROOT/Hunter.x.Hunter.2011.S01E51"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Naruto.S01E08"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Attack.on.Titan.S01E20"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Fullmetal.Alchemist.Brotherhood.S01E58"* "$TEST_DIR/" || true
rsync -av "$TV_ROOT/Noragami.S01E02"* "$TEST_DIR/" || true

# Count test files
TEST_COUNT=$(find "$TEST_DIR" -type d -maxdepth 1 | wc -l)
echo "✓ Test subset created: $TEST_COUNT folders"
echo ""

# =============================================================================
# PHASE 2: DRY RUN TEST - STANDARD MATCHING
# =============================================================================

echo "=== Phase 2: Dry Run Test - Standard Matching ==="

filebot -rename "$TEST_DIR" \
    --db TheTVDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action test \
    -non-strict \
    --log-file "$LOG_DIR/phase2_standard_dryrun.log" \
    --log all

echo "✓ Dry run complete. Review log: $LOG_DIR/phase2_standard_dryrun.log"
echo "  Check for:"
echo "  - Correct series identification"
echo "  - Proper season/episode mapping"
echo "  - Episode title accuracy"
echo "  - Any unmatched files"
echo ""
echo "Press Enter to continue or Ctrl+C to abort..."
read

# =============================================================================
# PHASE 3: DRY RUN TEST - ANIME MODE (ANIDB)
# =============================================================================

echo "=== Phase 3: Dry Run Test - Anime Mode ==="

# Test anime-specific matching
filebot -rename "$TEST_DIR" \
    --db AniDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action test \
    -non-strict \
    --log-file "$LOG_DIR/phase3_anime_dryrun.log" \
    --log all

echo "✓ Anime dry run complete. Review log: $LOG_DIR/phase3_anime_dryrun.log"
echo "  Compare AniDB vs TVDB results"
echo "  Determine which database works better per series"
echo ""
echo "Press Enter to continue or Ctrl+C to abort..."
read

# =============================================================================
# PHASE 4: TEST MOVE OPERATION
# =============================================================================

echo "=== Phase 4: Test Move Operation ==="
echo "WARNING: This will actually reorganize the test subset"
echo "The test directory will be modified"
echo ""
echo "Press Enter to proceed or Ctrl+C to abort..."
read

filebot -rename "$TEST_DIR" \
    --db TheTVDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action move \
    --conflict auto \
    -non-strict \
    --log-file "$LOG_DIR/phase4_test_move.log" \
    --log all

echo "✓ Test move complete"
echo ""

# =============================================================================
# PHASE 5: VERIFY RESULTS
# =============================================================================

echo "=== Phase 5: Verify Results ==="

# Show new structure
echo "New folder structure:"
find "$TEST_DIR" -type d | sort

echo ""
echo "File count verification:"
echo "  Original folders: $TEST_COUNT"
echo "  Video files found: $(find "$TEST_DIR" -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" | wc -l)"

echo ""
echo "Manual verification steps:"
echo "  1. Check that series folders have (year) suffix"
echo "  2. Verify Season XX folders exist"
echo "  3. Confirm episode files are named correctly"
echo "  4. Spot-check video playback"
echo "  5. Check for leftover empty folders"
echo ""
echo "Press Enter when manual verification is complete..."
read

# =============================================================================
# PHASE 6: FULL DRY RUN (ENTIRE TV DIRECTORY)
# =============================================================================

echo "=== Phase 6: Full Dry Run ==="
echo "This will process the ENTIRE TV directory in test mode"
echo "No files will be moved, but this will take time"
echo ""
echo "Press Enter to proceed or Ctrl+C to abort..."
read

filebot -rename "$TV_ROOT" \
    --db TheTVDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action test \
    --conflict auto \
    -non-strict \
    --log-file "$LOG_DIR/phase6_full_dryrun.log" \
    --log all

echo "✓ Full dry run complete"
echo ""
echo "Critical review required:"
echo "  Review: $LOG_DIR/phase6_full_dryrun.log"
echo "  Look for:"
echo "    - Unmatched files (these need manual intervention)"
echo "    - Incorrect series matches"
echo "    - Duplicate series folders"
echo "    - Special characters in filenames"
echo ""
echo "Create a list of problematic series to handle manually"
echo ""

# =============================================================================
# PHASE 7: STATISTICS AND REPORTING
# =============================================================================

echo "=== Phase 7: Generate Statistics ==="

# Parse log for statistics
TOTAL_FILES=$(grep -c "Rename" "$LOG_DIR/phase6_full_dryrun.log" || echo "0")
MATCHED=$(grep -c "\[TEST\]" "$LOG_DIR/phase6_full_dryrun.log" || echo "0")
FAILED=$(grep -c "Failed" "$LOG_DIR/phase6_full_dryrun.log" || echo "0")

cat > "$LOG_DIR/statistics.txt" << EOF
FileBot Full Dry Run Statistics
================================
Generated: $(date)

Total files processed: $TOTAL_FILES
Successfully matched: $MATCHED
Failed to match: $FAILED
Success rate: $(awk "BEGIN {printf \"%.2f%%\", ($MATCHED/$TOTAL_FILES)*100}")

Log files:
- Phase 2 (Standard): $LOG_DIR/phase2_standard_dryrun.log
- Phase 3 (Anime): $LOG_DIR/phase3_anime_dryrun.log
- Phase 4 (Test Move): $LOG_DIR/phase4_test_move.log
- Phase 6 (Full Dry Run): $LOG_DIR/phase6_full_dryrun.log

Next steps:
1. Review failed matches in phase6_full_dryrun.log
2. Identify series needing manual intervention
3. Decide on execution strategy (all at once vs. incremental)
4. Prepare exclusion list for problematic series
EOF

cat "$LOG_DIR/statistics.txt"

echo ""
echo "Statistics saved to: $LOG_DIR/statistics.txt"
echo ""

# =============================================================================
# PHASE 8: EXTRACT FAILED MATCHES
# =============================================================================

echo "=== Phase 8: Extract Failed Matches ==="

grep -i "failed\|error\|no match" "$LOG_DIR/phase6_full_dryrun.log" \
    > "$LOG_DIR/failed_matches.txt" || true

FAILED_COUNT=$(wc -l < "$LOG_DIR/failed_matches.txt")

echo "✓ Failed matches extracted: $FAILED_COUNT entries"
echo "  Review: $LOG_DIR/failed_matches.txt"
echo ""

if [ "$FAILED_COUNT" -gt 100 ]; then
    echo "WARNING: High failure rate detected ($FAILED_COUNT failures)"
    echo "Recommend manual investigation before proceeding"
fi

# =============================================================================
# EXECUTION DECISION POINT
# =============================================================================

echo ""
echo "======================================================================="
echo "TEST PHASE COMPLETE"
echo "======================================================================="
echo ""
echo "Review all logs before proceeding to production execution:"
cat "$LOG_DIR/statistics.txt"
echo ""
echo "PRODUCTION EXECUTION COMMAND (DO NOT RUN YET):"
echo ""
echo "filebot -rename \"$TV_ROOT\" \\"
echo "    --db TheTVDB \\"
echo "    --format \"{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}\" \\"
echo "    --action move \\"
echo "    --conflict auto \\"
echo "    -non-strict \\"
echo "    --log-file \"$LOG_DIR/production_run.log\" \\"
echo "    --log all"
echo ""
echo "Recommended approach:"
echo "  1. Review all logs thoroughly"
echo "  2. Handle failed matches manually"
echo "  3. Run production on one series at a time (use --filter)"
echo "  4. Verify each series before moving to next"
echo ""
echo "Example incremental execution:"
echo "  filebot -rename \"$TV_ROOT\" --filter \"n =~ /Seinfeld/\" ..."
echo ""
echo "======================================================================="

# =============================================================================
# HELPER FUNCTIONS FOR INCREMENTAL EXECUTION
# =============================================================================

cat > "$LOG_DIR/incremental_execution_examples.sh" << 'EOF'
#!/bin/bash
#
# Incremental Execution Examples
# Use these to process one series at a time
#

LOG_DIR="/var/home/deck/Documents/Code/media-automation/filebot_logs"
TV_ROOT="/run/media/deck/Fast_4TB_5/TV"

# Example 1: Process only Seinfeld
filebot -rename "$TV_ROOT" \
    --filter "n =~ /Seinfeld/" \
    --db TheTVDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action move \
    --conflict auto \
    -non-strict \
    --log-file "$LOG_DIR/seinfeld_run.log"

# Example 2: Process only Gravity Falls
filebot -rename "$TV_ROOT" \
    --filter "n =~ /Gravity Falls/" \
    --db TheTVDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action move \
    --conflict auto \
    -non-strict \
    --log-file "$LOG_DIR/gravity_falls_run.log"

# Example 3: Process anime with AniDB
filebot -rename "$TV_ROOT" \
    --filter "n =~ /Hunter x Hunter/" \
    --db AniDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action move \
    --conflict auto \
    -non-strict \
    --log-file "$LOG_DIR/hunter_x_hunter_run.log"

# Example 4: Process specific season
filebot -rename "$TV_ROOT" \
    --filter "s == 1 && n =~ /Attack on Titan/" \
    --db TheTVDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action move \
    --conflict auto \
    -non-strict \
    --log-file "$LOG_DIR/aot_s1_run.log"

# Example 5: Exclude problematic series
filebot -rename "$TV_ROOT" \
    --filter "!(n =~ /Doctor Who|One Piece|Monogatari/)" \
    --db TheTVDB \
    --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
    --action move \
    --conflict auto \
    -non-strict \
    --log-file "$LOG_DIR/bulk_except_problematic_run.log"

EOF

chmod +x "$LOG_DIR/incremental_execution_examples.sh"

echo "Incremental execution examples saved to:"
echo "  $LOG_DIR/incremental_execution_examples.sh"
echo ""

# =============================================================================
# CLEANUP TEST DIRECTORY (OPTIONAL)
# =============================================================================

echo "Clean up test directory? (y/N)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    rm -rf "$TEST_DIR"
    echo "✓ Test directory removed"
else
    echo "Test directory preserved at: $TEST_DIR"
fi

echo ""
echo "Script complete. Review logs before production execution."
