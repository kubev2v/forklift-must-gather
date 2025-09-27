# Commit Message Validation Guide

This guide explains how to write valid commit messages for this repository and how to fix validation errors.

## Required Format

All commit messages must include a description with a `Resolves:` line in one of these formats:

### Single Issue
```
Resolves: MTV-123
```

### Multiple Issues (Choose ONE separator style)

**Space-separated:**
```
Resolves: MTV-123 MTV-456
Resolves: MTV-123 MTV-456 MTV-789
```

**Comma-separated:**
```
Resolves: MTV-123, MTV-456
Resolves: MTV-123,MTV-456
Resolves: MTV-123, MTV-456, MTV-789
```

**"And" separated:**
```
Resolves: MTV-123 and MTV-456
Resolves: MTV-123 and MTV-456 and MTV-789
```

### No Associated Ticket
```
Resolves: None
```

## Important Rules

- **Do NOT mix separator styles** in the same line (e.g., `MTV-123, MTV-456 and MTV-789` is invalid)
- Issue numbers must be numeric (e.g., `MTV-abc` is invalid)
- Case matters: use `MTV-` not `mtv-`
- The `Resolves:` line can appear anywhere in the commit message body

## Example Valid Commit Messages

```
Fix user authentication bug

Updated the login validation to handle edge cases properly.
This resolves issues with special characters in passwords.

Resolves: MTV-456
```

```
Add new dashboard features

Implemented user dashboard with analytics and reporting.
Added export functionality and improved UI responsiveness.

Resolves: MTV-123, MTV-124, MTV-125
```

```
chore: update dependencies

Resolves: None
```

## Automatically Skipped Commits

The following commits are automatically skipped and don't need `Resolves:` lines:

- **Bot users:** dependabot, renovate, github-actions, ci, automated, etc.
- **Chore commits:** Messages containing `chore:` or `chore(` format

## Quick Fix Guide

### For the LATEST commit (most common case)
```bash
git commit --amend
# Edit your commit message to include a 'Resolves:' line
```

### For OLDER commits in your branch
```bash
git rebase -i HEAD~N  # where N is the number of commits to go back
# Mark commits as 'edit' or 'reword' to fix them
```

### For commits in a PULL REQUEST
1. Fix the commits using the methods above
2. Force push: `git push --force-with-lease`

## Common Validation Errors

### Missing Description
**Problem:** Your commit only has a subject line.

**Solution:** Add a description with a `Resolves:` line:
```bash
git commit --amend -m "Your subject line

Add your description here explaining what was changed.

Resolves: MTV-XXXX"
```

### Invalid Format
**Problem:** The `Resolves:` line doesn't match the required format.

**Examples of invalid formats:**
- `Resolves: MTV-` (missing number)
- `Resolves: mtv-123` (lowercase)
- `Resolves: MTV-123, MTV-456 and MTV-789` (mixed separators)
- `Resolves: MTV-123 JIRA-456` (mixed ticket systems)

**Solution:** Replace with a valid format from the examples above.

## Testing Your Commit Messages

You can test your commit messages locally using:
```bash
./scripts/validate-commits.sh                    # Validate latest commit
./scripts/validate-commits.sh --range HEAD~5..HEAD  # Validate last 5 commits
./scripts/validate-commits.sh --verbose         # Show detailed output
```

## Need Help?

If you're still having trouble with commit message validation:

1. Check the specific error message for details about what's wrong
2. Review the examples in this guide
3. Use the quick fix commands above to amend your commits
4. Test locally with the validation script before pushing

For questions about this validation process, please reach out to the development team.
