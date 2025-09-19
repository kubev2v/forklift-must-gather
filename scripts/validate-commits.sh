#!/bin/bash

# Standalone script to validate commit messages
# Can be used locally or by GitHub Actions

set -e

# Configuration
readonly BOT_PATTERNS=("dependabot" "renovate" "bot" "ci" "github-actions" "automated")
readonly MTV_PATTERN="^Resolves: MTV-[0-9]+$"
readonly NONE_PATTERN="^Resolves: None$"

# Default values
COMMIT_RANGE=""
VERBOSE=false

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --range)
        COMMIT_RANGE="$2"
        shift 2
        ;;
      --verbose|-v)
        VERBOSE=true
        shift
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Use --help for usage information" >&2
        exit 1
        ;;
    esac
  done
}

show_help() {
  cat << EOF
Usage: $0 [--range COMMIT_RANGE] [--verbose]

Options:
  --range COMMIT_RANGE  Git commit range to validate (e.g., HEAD~5..HEAD)
  --verbose, -v         Enable verbose output
  --help, -h           Show this help message

Examples:
  $0                                    # Validate latest commit
  $0 --range HEAD~5..HEAD              # Validate last 5 commits
  $0 --range origin/main..HEAD         # Validate commits in current branch
EOF
}

# Logging functions
log_verbose() {
  [[ "$VERBOSE" == true ]] && echo "$1"
}

log_error() {
  echo "$1" >&2
}

# Check if user is a bot
is_bot_user() {
  local email="$1"
  local name="$2"
  
  for pattern in "${BOT_PATTERNS[@]}"; do
    if [[ "$email" =~ $pattern ]] || [[ "$name" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# Check if commit is a chore
is_chore_commit() {
  local message="$1"
  echo "$message" | grep -qi "chore"
}

# Extract commit description (look for Resolves: line anywhere in commit)
extract_description() {
  local message="$1"
  
  # First try to find a "Resolves:" line anywhere in the message (exact case)
  local resolves_line=$(echo "$message" | grep -E "^Resolves: " | head -1)
  if [[ -n "$resolves_line" ]]; then
    echo "$resolves_line"
    return
  fi
  
  # Fallback to first non-empty line after subject if no Resolves line found
  local fallback_desc=$(echo "$message" | tail -n +2 | sed '/^$/d' | head -1)
  if [[ -n "$fallback_desc" ]]; then
    echo "$fallback_desc"
  else
    echo ""  # Return empty string for missing description
  fi
}

# Validate commit description format
validate_description() {
  local description="$1"
  echo "$description" | grep -qE "$MTV_PATTERN|$NONE_PATTERN"
}

# Print detailed error information for invalid commits
print_detailed_error() {
  local commit="$1"
  local author_name="$2"
  local author_email="$3"
  local commit_msg="$4"
  local error_type="$5"
  local description="$6"
  
  local short_sha=$(echo "$commit" | cut -c1-8)
  local subject=$(echo "$commit_msg" | head -1)
  
  echo ""
  echo "🚨 COMMIT VALIDATION FAILED"
  echo "═══════════════════════════════════════════════════════════════"
  echo "📋 Commit Details:"
  echo "   SHA:     $short_sha"
  echo "   Author:  $author_name <$author_email>"
  echo "   Subject: $subject"
  echo ""
  
  case "$error_type" in
    "missing-description")
      echo "❌ Problem: Missing commit description"
      echo "   Your commit only has a subject line, but we require a description"
      echo "   with a 'Resolves:' line."
      echo ""
      echo "🔧 How to fix:"
      echo "   Add a description to your commit with one of these formats:"
      echo "   • Resolves: MTV-<ticket-number>  (e.g., Resolves: MTV-123)"
      echo "   • Resolves: None  (if no ticket is associated)"
      echo ""
      echo "   To fix this commit:"
      echo "   git commit --amend -m \"$subject"
      echo ""
      echo "   <Add your description here>"
      echo ""
      echo "   Resolves: MTV-XXXX\""
      ;;
    "invalid-format")
      echo "❌ Problem: Invalid 'Resolves:' format"
      echo "   Found: $description"
      echo ""
      echo "🔧 How to fix:"
      echo "   Replace the description line with one of these exact formats:"
      echo "   • Resolves: MTV-<number>  (e.g., Resolves: MTV-123)"
      echo "   • Resolves: None  (if no ticket)"
      echo ""
      echo "   To fix this commit:"
      echo "   git commit --amend -m \"$subject"
      echo ""
      echo "   <Keep your existing description>"
      echo ""
      echo "   Resolves: MTV-XXXX\""
      echo ""
      echo "   Or if no ticket:"
      echo "   git commit --amend -m \"$subject"
      echo ""
      echo "   <Keep your existing description>"
      echo ""
      echo "   Resolves: None\""
      ;;
  esac
  
  echo ""
  echo "📖 More examples:"
  echo "   git commit -m \"Fix user authentication bug"
  echo ""
  echo "   Updated the login validation to handle edge cases properly."
  echo "   This resolves issues with special characters in passwords."
  echo ""
  echo "   Resolves: MTV-456\""
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
}

# Process a single commit
process_commit() {
  local commit="$1"
  local author_email author_name commit_msg description
  
  log_verbose "Checking commit: $commit"
  
  # Get commit details
  author_email=$(git show --format="%ae" -s "$commit")
  author_name=$(git show --format="%an" -s "$commit")
  commit_msg=$(git show --format="%B" -s "$commit")
  
  # Check bot user
  if is_bot_user "$author_email" "$author_name"; then
    log_verbose "🤖 Bot user detected ($author_name <$author_email>), skipping validation"
    echo "bot"
    return
  fi
  
  # Check chore commit
  if is_chore_commit "$commit_msg"; then
    log_verbose "🔧 Chore commit detected, skipping validation"
    echo "chore"
    return
  fi
  
  # Extract and validate description
  description=$(extract_description "$commit_msg")
  
  if [[ -z "$description" ]]; then
    print_detailed_error "$commit" "$author_name" "$author_email" "$commit_msg" "missing-description"
    echo "invalid"
    return
  fi
  
  if validate_description "$description"; then
    log_verbose "✅ Commit $commit: Valid format"
    echo "valid"
  else
    print_detailed_error "$commit" "$author_name" "$author_email" "$commit_msg" "invalid-format" "$description"
    echo "invalid"
  fi
}

# Main validation function
main() {
  local commits commit result
  local valid_count=0 invalid_count=0 skipped_count=0 chore_count=0
  local validation_failed=false
  
  # Set default commit range if not provided
  if [[ -z "$COMMIT_RANGE" ]]; then
    # Default to validating just the current HEAD commit
    local head_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
    if [[ -n "$head_commit" ]]; then
      commits="$head_commit"
      echo "🔍 Validating commit: $head_commit"
    else
      log_error "❌ Cannot determine HEAD commit"
      exit 1
    fi
  else
    echo "🔍 Validating commit messages in range: $COMMIT_RANGE"
    
    # Check if the commit range is valid first
    if ! git rev-list "$COMMIT_RANGE" >/dev/null 2>&1; then
      log_error "❌ Invalid commit range: $COMMIT_RANGE"
      log_error "   This may happen when the 'before' commit doesn't exist in the current branch"
      log_error "   (e.g., after a force push or rebase)"
      exit 1
    fi
    
    # Get commits to validate
    commits=$(git rev-list "$COMMIT_RANGE" 2>/dev/null || true)
    
    if [[ -z "$commits" ]]; then
      log_error "❌ No commits found in range: $COMMIT_RANGE"
      log_error "   The range exists but contains no commits"
      exit 1
    fi
  fi
  
  # Process each commit
  while IFS= read -r commit; do
    [[ -n "$commit" ]] || continue
    
    # Capture both output and result
    local output
    output=$(process_commit "$commit" 2>&1)
    result=$(echo "$output" | tail -1)
    
    # Show detailed errors immediately
    if [[ "$result" == "invalid" ]]; then
      echo "$output" | sed '$d'  # Show everything except the last line (result)
    fi
    
    case "$result" in
      "valid") 
        valid_count=$((valid_count + 1))
        ;;
      "invalid") 
        invalid_count=$((invalid_count + 1))
        validation_failed=true
        ;;
      "bot") 
        skipped_count=$((skipped_count + 1))
        ;;
      "chore") 
        chore_count=$((chore_count + 1))
        ;;
    esac
  done <<< "$commits"
  
  # Print summary
  echo ""
  echo "📊 Validation Summary:"
  echo "  ✅ Valid commits: $valid_count"
  echo "  ❌ Invalid commits: $invalid_count"
  echo "  🤖 Skipped (bot users): $skipped_count"
  echo "  🔧 Skipped (chore commits): $chore_count"
  
  if [[ "$validation_failed" == true ]]; then
    echo ""
    echo "💥 VALIDATION FAILED: $invalid_count commit(s) need to be fixed"
    echo ""
    echo "🛠️  QUICK FIX GUIDE:"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "For the LATEST commit (most common case):"
    echo "   git commit --amend"
    echo "   # Edit your commit message to include a 'Resolves:' line"
    echo ""
    echo "For OLDER commits in your branch:"
    echo "   git rebase -i HEAD~$((invalid_count + valid_count))"
    echo "   # Mark commits as 'edit' or 'reword' to fix them"
    echo ""
    echo "For commits in a PULL REQUEST:"
    echo "   1. Fix the commits using the methods above"
    echo "   2. Force push: git push --force-with-lease"
    echo ""
    echo "📋 Required format in commit description:"
    echo "   • Resolves: MTV-<number>  (e.g., MTV-123, MTV-4567)"
    echo "   • Resolves: None  (if no ticket associated)"
    echo ""
    echo "🚫 These commits are automatically skipped:"
    echo "   • Bot users (dependabot, renovate, github-actions, etc.)"
    echo "   • Commits with 'chore' in the message"
    echo ""
    echo "❓ Need help? Check the detailed errors above for specific fixes."
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    exit 1
  else
    echo "✅ All commit messages are valid!"
    exit 0
  fi
}

# Parse arguments and run main function
parse_args "$@"
main