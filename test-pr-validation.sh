#!/bin/bash

# Test script for PR validation functionality
# This script simulates different PR scenarios to test the validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE_SCRIPT="$SCRIPT_DIR/scripts/validate-commits.sh"

echo "🧪 Testing PR Validation Functionality"
echo "======================================"

# Test 1: Valid PR with multiple commits
echo "Test 1: Valid multi-commit PR range"
if $VALIDATE_SCRIPT --range HEAD~3..HEAD --verbose; then
    echo "✅ Test 1 PASSED: Valid PR commits"
else
    echo "❌ Test 1 FAILED: Valid PR commits should pass"
fi
echo ""

# Test 2: Single commit (simulating single-commit PR)
echo "Test 2: Single commit PR"
if $VALIDATE_SCRIPT --range HEAD~1..HEAD --verbose; then
    echo "✅ Test 2 PASSED: Single commit PR"
else
    echo "❌ Test 2 FAILED: Single commit PR should pass"
fi
echo ""

# Test 3: Empty range (edge case)
echo "Test 3: Empty commit range"
if $VALIDATE_SCRIPT --range HEAD..HEAD --verbose 2>/dev/null; then
    echo "❌ Test 3 FAILED: Empty range should fail"
else
    echo "✅ Test 3 PASSED: Empty range correctly failed"
fi
echo ""

echo "🎯 PR Validation Tests Complete!"
echo ""
echo "To test a real PR scenario:"
echo "1. Create a branch: git checkout -b test-pr"
echo "2. Make commits with proper format"
echo "3. Test with: $VALIDATE_SCRIPT --range main..HEAD --verbose"
