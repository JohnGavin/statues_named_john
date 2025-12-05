# Wiki Migration for Issue #76
# Date: December 5, 2025
# Purpose: Migrate Nix troubleshooting wiki content from randomwalk to claude_rix
# Issue: https://github.com/JohnGavin/statues_named_john/issues/76

# ==============================================================================
# OVERVIEW
# ==============================================================================
#
# This script documents the preparation work for migrating Nix environment
# troubleshooting documentation from the randomwalk wiki to the centralized
# claude_rix wiki.
#
# The actual wiki updates must be done manually via git operations on the
# wiki repositories, as GitHub wikis are separate git repos and cannot be
# modified via the GitHub API.
#
# ==============================================================================
# PREPARATION STEPS (Automated)
# ==============================================================================

# Step 1: Copy troubleshooting content to WIKI_CONTENT folder
# -----------------------------------------------------------------------------
# Command: cp archive/detailed-docs/NIX_TROUBLESHOOTING.md WIKI_CONTENT/Nix-Environment-Troubleshooting.md
# Result: Created WIKI_CONTENT/Nix-Environment-Troubleshooting.md (837 lines)

# Step 2: Update WIKI_CONTENT README
# -----------------------------------------------------------------------------
# Edited: WIKI_CONTENT/README.md
# Added row to table:
#   | `Nix-Environment-Troubleshooting.md` | [Nix-Environment-Troubleshooting](...) | 🔄 Ready to Publish | 837 |

# Step 3: Create migration instructions
# -----------------------------------------------------------------------------
# Created: WIKI_CONTENT/MIGRATION_INSTRUCTIONS_ISSUE_76.md
# Contains:
#   - Step-by-step manual instructions for wiki migration
#   - Git commands for both wikis
#   - Cross-reference template for randomwalk wiki
#   - Verification checklist
#   - Troubleshooting tips

# ==============================================================================
# MANUAL STEPS REQUIRED
# ==============================================================================
#
# The following steps must be performed manually by the user:
#
# 1. Publish to claude_rix wiki:
#    - Clone https://github.com/JohnGavin/claude_rix.wiki.git
#    - Copy Nix-Environment-Troubleshooting.md
#    - Commit and push
#    - Verify at wiki URL
#
# 2. Update randomwalk wiki:
#    - Clone https://github.com/JohnGavin/randomwalk.wiki.git
#    - Replace Troubleshooting-Nix-Environment.md with cross-reference
#    - Commit and push
#    - Verify cross-reference works
#
# 3. Update navigation (optional):
#    - Add link to new page in claude_rix wiki Home page
#
# 4. Close issue #76:
#    - Add summary comment
#    - Close issue
#
# Detailed instructions in: WIKI_CONTENT/MIGRATION_INSTRUCTIONS_ISSUE_76.md
#
# ==============================================================================
# FILES CREATED/MODIFIED
# ==============================================================================

# New files:
files_created <- c(
  "/Users/johngavin/docs_gh/claude_rix/WIKI_CONTENT/Nix-Environment-Troubleshooting.md",
  "/Users/johngavin/docs_gh/claude_rix/WIKI_CONTENT/MIGRATION_INSTRUCTIONS_ISSUE_76.md",
  "/Users/johngavin/docs_gh/claude_rix/statues_named_john/R/setup/wiki_migration_issue_76.R"
)

# Modified files:
files_modified <- c(
  "/Users/johngavin/docs_gh/claude_rix/WIKI_CONTENT/README.md"
)

# ==============================================================================
# RATIONALE
# ==============================================================================
#
# Why centralize to claude_rix wiki?
#
# 1. Single source of truth: All projects share same Nix environment setup
# 2. Easier maintenance: Update once, applies to all projects
# 3. Better discoverability: Users find all project docs in one place
# 4. Reduce duplication: No need to sync content across multiple wikis
# 5. Consistency: Same troubleshooting steps for all claude_rix projects
#
# ==============================================================================
# VERIFICATION CHECKLIST
# ==============================================================================
#
# Before closing issue #76:
#
# [ ] WIKI_CONTENT/Nix-Environment-Troubleshooting.md exists and is complete
# [ ] MIGRATION_INSTRUCTIONS_ISSUE_76.md provides clear step-by-step guide
# [ ] User has executed manual wiki migration steps
# [ ] New page published on claude_rix wiki
# [ ] randomwalk wiki updated with cross-reference
# [ ] All links verified working
# [ ] Issue #76 closed with summary
#
# ==============================================================================
# RELATED DOCUMENTATION
# ==============================================================================

related_docs <- list(
  wiki_instructions = "/Users/johngavin/docs_gh/claude_rix/WIKI_CONTENT/MIGRATION_INSTRUCTIONS_ISSUE_76.md",
  wiki_content = "/Users/johngavin/docs_gh/claude_rix/WIKI_CONTENT/Nix-Environment-Troubleshooting.md",
  original_source = "/Users/johngavin/docs_gh/claude_rix/archive/detailed-docs/NIX_TROUBLESHOOTING.md",
  wiki_readme = "/Users/johngavin/docs_gh/claude_rix/WIKI_CONTENT/README.md",
  github_issue = "https://github.com/JohnGavin/statues_named_john/issues/76"
)

# ==============================================================================
# NEXT SESSION
# ==============================================================================
#
# If continuing in a new session:
#
# 1. Read WIKI_CONTENT/MIGRATION_INSTRUCTIONS_ISSUE_76.md
# 2. Execute manual steps if not yet done
# 3. Verify all links working
# 4. Close issue #76
#
# ==============================================================================
# END OF LOG
# ==============================================================================

cat("✅ Preparation complete for issue #76\n")
cat("📄 Review instructions: WIKI_CONTENT/MIGRATION_INSTRUCTIONS_ISSUE_76.md\n")
cat("🔧 Manual wiki migration steps required\n")
