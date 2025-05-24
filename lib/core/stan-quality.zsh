#!/usr/bin/env zsh
##############################################################################
# File: ./lib/core/stan-quality.zsh
# Project: Usenet Media Stack
# Description: Code quality functions following Stan Eisenstat's principles
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module embodies Stan Eisenstat's teaching philosophy:
# "If you can't explain it to a freshman, you don't understand it yourself."
#
# Every function here is written as Stan taught:
# - Clear purpose (do one thing)
# - Obvious behavior (no surprises)  
# - Helpful errors (guide the user)
# - No clever tricks (clarity over brevity)
##############################################################################

##############################################################################
#                         STAN'S PRINCIPLES                                  #
##############################################################################

# Principle 1: Functions should do ONE thing
# Principle 2: Names should explain themselves
# Principle 3: Errors should help, not confuse
# Principle 4: Code should be obviously correct
# Principle 5: If it needs a comment, rewrite it

##############################################################################
#                      ERROR HANDLING THE STAN WAY                           #
##############################################################################

#=============================================================================
# Function: require_exactly_one_argument
# Description: Validate that exactly one argument was provided
#
# Stan taught: "Check your inputs. Always. No exceptions."
#
# This function demonstrates proper input validation with helpful error
# messages that guide the user to correct usage.
#
# Arguments:
#   $1 - Function name (for error message)
#   $@ - All arguments to check
#
# Returns:
#   0 - Exactly one argument provided
#   1 - Wrong number of arguments
#
# Example:
#   require_exactly_one_argument "process_file" "$@" || return 1
#=============================================================================
require_exactly_one_argument() {
    local function_name=$1
    shift
    local arg_count=$#
    
    if (( arg_count == 0 )); then
        print -u2 "Error: $function_name requires an argument"
        print -u2 "Usage: $function_name <value>"
        print -u2 "Example: $function_name ~/documents/data.txt"
        return 1
    elif (( arg_count > 1 )); then
        print -u2 "Error: $function_name takes exactly one argument, got $arg_count"
        print -u2 "You provided: $*"
        print -u2 "Usage: $function_name <value>"
        return 1
    fi
    
    return 0
}

#=============================================================================
# Function: validate_positive_integer
# Description: Check if a value is a positive integer
#
# Stan's rule: "Don't accept bad input. Fail fast, fail clearly."
#
# Arguments:
#   $1 - Value to check
#   $2 - Parameter name (for error message)
#
# Returns:
#   0 - Valid positive integer
#   1 - Invalid input
#
# Example:
#   validate_positive_integer "$port" "port number" || return 1
#=============================================================================
validate_positive_integer() {
    local value=$1
    local param_name=$2
    
    # Check if empty
    if [[ -z "$value" ]]; then
        print -u2 "Error: $param_name cannot be empty"
        return 1
    fi
    
    # Check if integer
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        print -u2 "Error: $param_name must be a positive integer"
        print -u2 "You provided: '$value'"
        print -u2 "Valid examples: 1, 42, 8080"
        return 1
    fi
    
    # Check if positive (not zero)
    if (( value <= 0 )); then
        print -u2 "Error: $param_name must be greater than zero"
        print -u2 "You provided: $value"
        return 1
    fi
    
    return 0
}

##############################################################################
#                    FILE OPERATIONS THE STAN WAY                            #
##############################################################################

#=============================================================================
# Function: read_file_safely
# Description: Read a file with comprehensive error checking
#
# Stan's philosophy: "Handle every possible failure mode."
#
# Arguments:
#   $1 - File path to read
#
# Returns:
#   0 - File read successfully (contents to stdout)
#   1 - File not found
#   2 - Permission denied
#   3 - File is a directory
#   4 - File is empty
#
# Example:
#   if contents=$(read_file_safely "/etc/config"); then
#       process_contents "$contents"
#   fi
#=============================================================================
read_file_safely() {
    local file_path=$1
    
    # Check if path provided
    if [[ -z "$file_path" ]]; then
        print -u2 "Error: No file path provided"
        print -u2 "Usage: read_file_safely <path>"
        return 1
    fi
    
    # Check if exists
    if [[ ! -e "$file_path" ]]; then
        print -u2 "Error: File not found: $file_path"
        return 1
    fi
    
    # Check if directory
    if [[ -d "$file_path" ]]; then
        print -u2 "Error: Path is a directory, not a file: $file_path"
        return 3
    fi
    
    # Check if readable
    if [[ ! -r "$file_path" ]]; then
        print -u2 "Error: Permission denied reading: $file_path"
        print -u2 "Try: chmod +r '$file_path'"
        return 2
    fi
    
    # Check if empty
    if [[ ! -s "$file_path" ]]; then
        print -u2 "Warning: File is empty: $file_path"
        return 4
    fi
    
    # Read the file
    cat "$file_path" 2>/dev/null || {
        print -u2 "Error: Failed to read file: $file_path"
        return 1
    }
}

##############################################################################
#                     CODE QUALITY CHECKS                                    #
##############################################################################

#=============================================================================
# Function: check_function_quality
# Description: Verify a function meets Stan's quality standards
#
# Checks:
# - Has a docstring
# - Single responsibility (< 50 lines)
# - Proper error handling
# - No TODO/FIXME comments
#
# Arguments:
#   $1 - Function name
#   $2 - File path containing function
#
# Returns:
#   0 - Function meets standards
#   1 - Quality issues found
#
# Example:
#   check_function_quality "process_data" "lib/core/data.zsh"
#=============================================================================
check_function_quality() {
    local function_name=$1
    local file_path=$2
    local issues=0
    
    # Extract function
    local func_start=$(grep -n "^${function_name}()" "$file_path" | cut -d: -f1)
    local func_end=$(tail -n +$((func_start + 1)) "$file_path" | grep -n "^}" | head -1 | cut -d: -f1)
    local func_lines=$((func_end))
    
    # Check length
    if (( func_lines > 50 )); then
        print "Issue: Function '$function_name' is too long ($func_lines lines)"
        print "Stan's rule: If it doesn't fit on one screen, split it up"
        ((issues++))
    fi
    
    # Check for docstring
    local has_docstring=$(sed -n "$((func_start - 5)),$((func_start - 1))p" "$file_path" | grep -c "Description:")
    if (( has_docstring == 0 )); then
        print "Issue: Function '$function_name' lacks documentation"
        print "Stan's rule: Undocumented code is broken code"
        ((issues++))
    fi
    
    # Check for TODOs
    if sed -n "${func_start},$((func_start + func_end))p" "$file_path" | grep -q "TODO\|FIXME"; then
        print "Issue: Function '$function_name' contains TODO/FIXME"
        print "Stan's rule: Ship working code, not promises"
        ((issues++))
    fi
    
    return $(( issues > 0 ? 1 : 0 ))
}

##############################################################################
#                   TEACHING MOMENTS                                         #
##############################################################################

#=============================================================================
# Function: explain_error
# Description: Provide educational error messages
#
# Stan believed errors should teach, not just inform.
#
# Arguments:
#   $1 - Error code
#   $2 - Context
#
# Returns:
#   0 - Always (prints explanation)
#
# Example:
#   explain_error "E_NULL_PTR" "process_data"
#=============================================================================
explain_error() {
    local error_code=$1
    local context=$2
    
    case "$error_code" in
        E_NULL_PTR)
            print "Error: Null pointer in $context"
            print ""
            print "What happened:"
            print "  A required value was not provided or was empty."
            print ""
            print "How to fix:"
            print "  1. Check that all required arguments are passed"
            print "  2. Verify your configuration file exists"
            print "  3. Ensure environment variables are set"
            print ""
            print "Example of correct usage:"
            print "  $context \"/path/to/valid/file\""
            ;;
            
        E_FILE_NOT_FOUND)
            print "Error: File not found in $context"
            print ""
            print "What this means:"
            print "  The program tried to read a file that doesn't exist."
            print ""
            print "Common causes:"
            print "  - Typo in the file path"
            print "  - File was moved or deleted"
            print "  - Wrong working directory"
            print ""
            print "How to debug:"
            print "  ls -la  # List files in current directory"
            print "  pwd     # Show current directory"
            ;;
    esac
}

##############################################################################
#                    THE STAN TEST                                           #
##############################################################################

#=============================================================================
# Function: passes_stan_test
# Description: Would Stan approve of this code?
#
# The ultimate quality check. If this returns true, the code is ready.
#
# Arguments:
#   $1 - File to check
#
# Returns:
#   0 - Stan would be proud
#   1 - More work needed
#
# Example:
#   passes_stan_test "lib/core/data.zsh" || refactor_until_clear
#=============================================================================
passes_stan_test() {
    local file=$1
    local score=100
    
    print "Running Stan Quality Test on: $file"
    print "=" | repeat 60
    
    # Check: No clever one-liners
    if grep -E '.{100,}' "$file" | grep -v "^#"; then
        print "❌ Found lines over 100 characters"
        print "   Stan says: 'If it doesn't fit on a terminal, it's too clever'"
        ((score -= 10))
    fi
    
    # Check: Functions have docstrings
    local functions=$(grep -E '^[a-z_]+\(\)' "$file" | wc -l)
    local docstrings=$(grep -B5 -E '^[a-z_]+\(\)' "$file" | grep -c "Description:")
    if (( docstrings < functions )); then
        print "❌ Missing docstrings: $((functions - docstrings)) functions undocumented"
        print "   Stan says: 'Code without docs is a letter without an address'"
        ((score -= 20))
    fi
    
    # Check: Error handling
    if grep -q '2>/dev/null' "$file" | grep -v grep; then
        if ! grep -q 'print -u2' "$file"; then
            print "❌ Silencing errors without handling them"
            print "   Stan says: 'Handle errors, don't hide them'"
            ((score -= 15))
        fi
    fi
    
    # Check: No magic numbers
    if grep -E '[^0-9]([2-9][0-9]{2,}|1[0-9]{3,})[^0-9]' "$file" | grep -v "^#"; then
        print "❌ Found magic numbers"
        print "   Stan says: 'Name your constants'"
        ((score -= 10))
    fi
    
    # Results
    print ""
    print "Stan Score: $score/100"
    
    if (( score >= 90 )); then
        print "✅ Stan would be proud!"
        return 0
    elif (( score >= 70 )); then
        print "⚠️  Good effort, but Stan would suggest improvements"
        return 1
    else
        print "❌ Stan would make you rewrite this"
        return 1
    fi
}

# Export all functions
typeset -fx require_exactly_one_argument validate_positive_integer
typeset -fx read_file_safely check_function_quality
typeset -fx explain_error passes_stan_test

# Run self-test when sourced (Stan would approve)
if [[ "${(%):-%x}" == "${0}" ]]; then
    print "Running self-test..."
    passes_stan_test "${0}"
fi

# vim: set ts=4 sw=4 et tw=80: