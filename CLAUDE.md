#!/usr/bin/env zsh
##############################################################################
# File: ./CLAUDE.md
# Project: Usenet Media Stack
# Description: Development guidelines and standards for AI-assisted coding
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 2.0.0
#
# This file provides comprehensive guidance to Claude Code and other AI
# assistants when working with this repository. It establishes coding
# standards, architectural decisions, and development practices.
##############################################################################

##############################################################################
#                            PROJECT OVERVIEW                                #
##############################################################################

This is a production-grade media automation stack using Docker Compose,
designed for both single-device and multi-device deployments. The system
manages Usenet downloads, media organization, and streaming with 20+
integrated services.

Target Audience: Power users and enthusiasts who want a professional-grade
media server without the complexity of enterprise solutions.

##############################################################################
#                          CRITICAL STANDARDS                                #
##############################################################################

#=============================================================================
# 1. FILE STRUCTURE AND HEADERS
#=============================================================================

EVERY file must begin with:

```zsh
#!/usr/bin/env zsh
##############################################################################
# File: <path relative to project root>
# Project: Usenet Media Stack
# Description: <one line description>
# Author: Joseph Lanzone <j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: X.Y.Z
# License: MIT
#
# <Detailed description of what this file does, wrapped at 80 chars>
##############################################################################
```

#=============================================================================
# 2. CODE STYLE REQUIREMENTS
#=============================================================================

- Language: zsh (NOT bash, NOT sh)
- Line width: 80 characters MAXIMUM
- Indentation: 4 spaces (NO tabs)
- Functions: MUST have docstring blocks
- Sections: Delimited with 78 # characters
- Variables: lowercase_with_underscores
- Constants: UPPERCASE_WITH_UNDERSCORES
- File paths: ALWAYS relative to project root

#=============================================================================
# 3. FUNCTION DOCUMENTATION
#=============================================================================

EVERY function must have:

```zsh
#=============================================================================
# Function: function_name
# Description: One-line summary
#
# Detailed description of what the function does, including any important
# implementation details or limitations.
#
# Arguments:
#   $1 - parameter_name (type, required/optional)
#        Detailed description of parameter
#   $2 - another_param (optional, default: value)
#        Description of this parameter
#
# Returns:
#   0 - Success condition
#   1 - Error condition 1
#   2 - Error condition 2
#
# Side Effects:
#   - Creates files in /tmp
#   - Modifies global variable X
#   - Prints to stdout/stderr
#
# Example:
#   if function_name "arg1" "arg2"; then
#       echo "Success"
#   fi
#=============================================================================
```

#=============================================================================
# 4. ERROR HANDLING
#=============================================================================

- ALWAYS check command success
- NEVER use 'set -e' alone (use 'set -euo pipefail')
- Provide meaningful error messages
- Include recovery suggestions
- Use proper exit codes

#=============================================================================
# 5. DIRECTORY STRUCTURE
#=============================================================================

IDEAL structure (NOT current state):

```
usenet-media-stack/
├── usenet                  # Single entry point (zsh)
├── README.md              # Beautiful with GIFs
├── LICENSE                # MIT license
├── docker-compose.yml     # Main compose file
├── .env.example          # Example configuration
├── .gitignore           # Proper ignores
├── lib/                 # ALL implementation
│   ├── core.zsh        # Core functions
│   ├── platform.zsh    # OS compatibility
│   ├── docker.zsh      # Docker management
│   ├── storage.zsh     # JBOD/storage
│   ├── ui.zsh          # User interface
│   └── commands/       # Command implementations
├── config/             # Service configurations
├── docs/              # Minimal documentation
│   ├── GUIDE.md       # Complete user guide
│   ├── STORAGE.md     # JBOD setup guide
│   └── DEVELOPMENT.md # For contributors
└── tests/             # Automated tests
```

##############################################################################
#                         CURRENT STATE ISSUES                               #
##############################################################################

As of 2025-05-24, this project has MAJOR issues:

1. **File Sprawl**: 59 files in root (should be <10)
2. **Entry Points**: 30+ scripts (should be 1)
3. **Documentation**: 18 MD files (should be 3-4)
4. **Style**: Mixed bash/sh instead of pure zsh
5. **Organization**: No clear module structure
6. **Storage Docs**: Missing JBOD documentation
7. **Docstrings**: Most functions undocumented

##############################################################################
#                         REFACTORING PLAN                                   #
##############################################################################

#=============================================================================
# PHASE 1: CONSOLIDATION (8 hours)
#=============================================================================

## Step 1.1: Create Clean Entry Point (1 hour)
- [ ] Create new `usenet` script in zsh with proper header
- [ ] Implement command routing (setup, manage, storage, etc.)
- [ ] Add comprehensive --help system
- [ ] Test all command paths

## Step 1.2: Create lib/ Structure (2 hours)
- [ ] mkdir -p lib/{commands,core,platform}
- [ ] Create lib/core.zsh with shared functions
- [ ] Create lib/platform.zsh with OS detection
- [ ] Create lib/ui.zsh with display functions
- [ ] Create lib/help.zsh with help text

## Step 1.3: Move Core Logic (3 hours)
Scripts to consolidate into lib/commands/:
- [ ] one-click-setup.sh → lib/commands/setup.zsh
- [ ] manage.sh → lib/commands/manage.zsh
- [ ] setup-all.sh → merge into setup.zsh
- [ ] configure-*.sh → lib/commands/configure.zsh
- [ ] All test scripts → lib/commands/test.zsh

## Step 1.4: Delete Redundant Files (1 hour)
Files to DELETE after moving logic:
- [ ] All *.sh files in root (except during transition)
- [ ] All test-*.sh files
- [ ] All setup-*.sh variants
- [ ] quick-install.sh, auto-install-deps.sh (merge to setup)

## Step 1.5: Documentation Consolidation (1 hour)
Keep ONLY these docs:
- [ ] README.md (rewrite with GIFs)
- [ ] docs/GUIDE.md (merge all guides)
- [ ] docs/STORAGE.md (NEW - JBOD guide)
- [ ] docs/TROUBLESHOOTING.md

DELETE these docs:
- [ ] AUTOMATED_SETUP.md
- [ ] COMPLETE_DOCUMENTATION.md
- [ ] MEDIA_SERVICES_SETUP.md
- [ ] MIGRATION_NOTES.md
- [ ] PROJECT_STATUS.md
- [ ] SETUP_GUIDE.md
- [ ] STACK_RECOMMENDATIONS.md
- [ ] TECHNICAL_REFERENCE.md
- [ ] All *PLAN*.md, *REPORT*.md files

#=============================================================================
# PHASE 2: STANDARDIZATION (4 hours)
#=============================================================================

## Step 2.1: ZSH Conversion (1 hour)
For EVERY file in lib/:
- [ ] Change shebang to #!/usr/bin/env zsh
- [ ] Add proper file header with location
- [ ] Update bash-specific syntax to zsh
- [ ] Test each file still works

## Step 2.2: Add Headers (1 hour)
EVERY file needs:
```zsh
#!/usr/bin/env zsh
##############################################################################
# File: ./lib/path/to/file.zsh
# Project: Usenet Media Stack
# Description: One-line description
# Author: Joseph Lanzone <j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# Detailed description wrapped at 80 characters explaining what this
# file does and how it fits into the overall system.
##############################################################################
```

## Step 2.3: Function Documentation (1.5 hours)
For EVERY function add:
```zsh
#=============================================================================
# Function: function_name
# Description: One-line summary
#
# Detailed description...
#
# Arguments:
#   $1 - name (type, required/optional)
#        Description
#
# Returns:
#   0 - Success
#   1 - Error condition
#
# Example:
#   function_name "arg1" "arg2"
#=============================================================================
```

## Step 2.4: Code Formatting (0.5 hours)
- [ ] Enforce 80-character line limit
- [ ] Add section dividers (78 #'s)
- [ ] Consistent 4-space indentation
- [ ] Remove all tabs

#=============================================================================
# PHASE 3: DOCUMENTATION (4 hours)
#=============================================================================

## Step 3.1: README.md Rewrite (1.5 hours)
Structure:
```markdown
<p align="center">
  <img src="docs/assets/banner.png" width="600">
</p>

<p align="center">
  [badges for version, platform, license]
</p>

# 🎬 Usenet Media Stack

One line value prop.

![Demo GIF](docs/assets/demo.gif)

## ✨ Features
- 🚀 One-command deployment
- 💾 JBOD support
- 🔒 Secure by default

## 📦 What's Included
[Table of services]

## 🚀 Quick Start
```bash
git clone ...
cd usenet-media-stack
./usenet setup
```

## 💾 Storage
[Brief intro, link to full guide]

## 📖 Documentation
- [Complete Guide](docs/GUIDE.md)
- [Storage Setup](docs/STORAGE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
```

## Step 3.2: STORAGE.md Creation (1.5 hours)
Must include:
- [ ] What is JBOD?
- [ ] Benefits over RAID for media
- [ ] Initial setup walkthrough
- [ ] Adding drives step-by-step
- [ ] Monitoring capacity
- [ ] Handling drive failures
- [ ] Performance optimization
- [ ] Backup strategies

## Step 3.3: Consolidate Guides (1 hour)
Merge into docs/GUIDE.md:
- [ ] Installation steps
- [ ] Service descriptions
- [ ] Configuration options
- [ ] 1Password integration
- [ ] Network setup
- [ ] Security hardening
- [ ] Update procedures
- [ ] Common workflows

#=============================================================================
# PHASE 4: POLISH (4 hours)
#=============================================================================

## Step 4.1: Visual Assets (1 hour)
- [ ] Create banner image (docs/assets/banner.png)
- [ ] Record demo GIF showing setup process
- [ ] Add service logos/icons
- [ ] Create architecture diagram

## Step 4.2: GitHub Polish (1 hour)
- [ ] Add badges: version, platform, license, docker
- [ ] Create .github/ISSUE_TEMPLATE/
- [ ] Add .github/PULL_REQUEST_TEMPLATE.md
- [ ] Update .gitignore (remove test outputs)
- [ ] Add GitHub Actions for testing

## Step 4.3: Final Cleanup (1 hour)
DELETE these files:
- [ ] All .md files with PLAN, STATUS, REPORT in name
- [ ] All test output files
- [ ] Any .bak or ~ files
- [ ] Duplicate scripts

## Step 4.4: Testing Suite (1 hour)
Create tests/:
- [ ] tests/unit/ - Function tests
- [ ] tests/integration/ - Full stack tests
- [ ] tests/platform/ - OS-specific tests
- [ ] Add GitHub Actions workflow

#=============================================================================
# PHASE 5: FINAL CHECKLIST
#=============================================================================

Before declaring complete:

## Code Quality
- [ ] All files use zsh shebang
- [ ] All files have proper headers
- [ ] All functions have docstrings
- [ ] 80-char line limit enforced
- [ ] No tabs, only spaces

## File Structure
- [ ] Root has <10 files
- [ ] All logic in lib/
- [ ] Documentation in docs/
- [ ] Tests in tests/

## Documentation
- [ ] README is beautiful with GIFs
- [ ] STORAGE.md explains JBOD
- [ ] Help text is comprehensive
- [ ] Examples for every command

## Functionality
- [ ] Single entry point works
- [ ] All commands tested
- [ ] Cross-platform verified
- [ ] Error messages helpful

## GitHub Ready
- [ ] Professional appearance
- [ ] Clear value proposition
- [ ] Easy to understand
- [ ] Impressive to engineers

##############################################################################
#                    IMMEDIATE NEXT STEPS                                    #
##############################################################################

When context resumes, START HERE:

1. **Create lib/ structure**
   ```bash
   mkdir -p lib/{commands,core,platform}
   ```

2. **Create the perfect usenet entry point**
   - Copy from usenet-clean example
   - Add proper header
   - Test it works

3. **Move one-click-setup.sh logic to lib/commands/setup.zsh**
   - Extract core functionality
   - Add proper headers and docstrings
   - Make it beautiful

4. **Delete the mess**
   - Remove all test-*.sh files
   - Remove all PLAN/STATUS/REPORT.md files
   - Keep ONLY essential files

5. **Create STORAGE.md**
   - This is the biggest missing piece
   - Users have NO idea how to add drives

##############################################################################
#                         CODING GUIDELINES                                  #
##############################################################################

#=============================================================================
# WHEN ADDING NEW FEATURES
#=============================================================================

1. NEVER create new scripts in root
2. ALWAYS add to lib/ structure
3. MUST include proper headers
4. MUST include docstrings
5. MUST handle errors gracefully
6. MUST update help system

#=============================================================================
# WHEN FIXING BUGS
#=============================================================================

1. Understand root cause first
2. Add test to prevent regression
3. Update documentation if needed
4. Check for similar issues elsewhere
5. Test on Linux AND macOS

#=============================================================================
# COMMIT STANDARDS
#=============================================================================

Format: <type>: <description>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation only
- style: Code style changes
- refactor: Code restructuring
- test: Test additions/changes
- chore: Maintenance tasks

##############################################################################
#                      INTERACTION GUIDELINES                                #
##############################################################################

When Claude Code works on this project:

1. **Prioritize Simplicity**: One way to do things
2. **Document Everything**: No magic, explain it all
3. **Think Cross-Platform**: Linux, macOS, WSL2
4. **Assume Beginners**: Make it monkey-proof
5. **Professional Polish**: Would a FAANG engineer approve?

##############################################################################
#                         QUALITY CHECKLIST                                  #
##############################################################################

Before ANY commit, ensure:

□ Proper zsh shebang (#!/usr/bin/env zsh)
□ File header with location
□ 80-character line limit
□ Function docstrings
□ Error handling
□ Cross-platform compatibility
□ Updated help text
□ No new files in root
□ Tests pass

##############################################################################
#                            ULTIMATE GOAL                                   #
##############################################################################

Create a media automation system so clean, well-documented, and robust that:

1. A beginner can deploy it successfully
2. A senior engineer would be impressed by the code
3. It works flawlessly on any Unix system
4. It becomes the gold standard for Docker Compose projects

Remember: We're not just writing code, we're crafting a masterpiece that
would make Kernighan and Ritchie proud.

# vim: set ts=4 sw=4 et tw=80: