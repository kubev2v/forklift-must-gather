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
    echo "No description found"
  fi
}

# Validate commit description format
validate_description() {
  local description="$1"
  echo "$description" | grep -qE "$MTV_PATTERN|$NONE_PATTERN"
}

# Process a single commit
process_commit() {
  local commit="$1"
  local author_email author_name commit_msg description
  
  echo "DEBUG: process_commit called with: '$commit'"
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
    log_error "❌ Commit $commit: Missing commit description"
    log_error "   Author: $author_name <$author_email>"
    log_error "   Message: $(echo "$commit_msg" | head -1)"
    log_error "   Expected format in description: Resolves: MTV-<number> or Resolves: None"
    echo ""
    echo "invalid"
    return
  fi
  
  if validate_description "$description"; then
    log_verbose "✅ Commit $commit: Valid format"
    echo "valid"
  else
    log_error "❌ Commit $commit: Invalid commit description format"
    log_error "   Author: $author_name <$author_email>"
    log_error "   Subject: $(echo "$commit_msg" | head -1)"
    log_error "   Description: $description"
    log_error "   Expected format: Resolves: MTV-<number> or Resolves: None"
    echo ""
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
    echo "No commit range provided, will validate HEAD commit only"
    # Just validate the current HEAD commit
    local head_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
    if [[ -n "$head_commit" ]]; then
      commits="$head_commit"
      echo "🔍 Validating single commit: $head_commit"
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
  echo "DEBUG: About to process commits: '$commits'"
  while IFS= read -r commit; do
    echo "DEBUG: Processing commit line: '$commit'"
    [[ -n "$commit" ]] || continue
    echo "DEBUG: About to validate commit: $commit"
    result=$(process_commit "$commit" 2>&1 | tail -1)
    echo "DEBUG: Validation result: '$result'"
    
    case "$result" in
      "valid") ((valid_count++)) ;;
      "invalid") 
        ((invalid_count++))
        validation_failed=true
        ;;
      "bot") ((skipped_count++)) ;;
      "chore") ((chore_count++)) ;;
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
    log_error "❌ Commit message validation failed!"
    echo ""
    echo "Commit messages must include one of these formats in the description:"
    echo "  • Resolves: MTV-<number>"
    echo "  • Resolves: None"
    echo ""
    echo "Exceptions:"
    echo "  • Bot users (dependabot, renovate, ci, github-actions, etc.)"
    echo "  • Commits containing 'chore' in the message"
    echo ""
    echo "Example commit:"
    echo "  Subject: Fix bug in data processing"
    echo "  Description: Resolves: MTV-123"
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