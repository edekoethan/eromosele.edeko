#!/usr/bin/env bash
# replace_absolute_paths.sh
# Preview and (optionally) automatically replace absolute-root src/href paths
# so they include the repo base (/eromosele.edeko/).
#
# Usage:
#   ./replace_absolute_paths.sh        # preview, ask to proceed, create branch, replace, commit
#   ./replace_absolute_paths.sh --yes  # same but don't prompt
#   ./replace_absolute_paths.sh --publish --yes   # also run ./publish_local.sh after commit
#
set -euo pipefail

REPO_BASE="eromosele.edeko"
PREFIX="/${REPO_BASE}/"
BRANCH="fix/absolute-paths-$(date -u +%Y%m%d%H%M%S)"
DRY_RUN=true
AUTO_YES=false
DO_PUBLISH=false

for arg in "$@"; do
  case "$arg" in
    --yes) AUTO_YES=true; DRY_RUN=false ;;
    --publish) DO_PUBLISH=true ;;
    --help|-h) echo "Usage: $0 [--yes] [--publish]"; exit 0 ;;
  esac
done

if [ "$AUTO_YES" = false ]; then
  echo "Preview mode. Run with --yes to apply changes without prompting."
fi

# File types to search/replace
# Adjust or extend as needed
FILE_GLOBS=( "src/**/*.astro" "src/**/*.md" "src/**/*.html" "src/**/*.js" "src/**/*.ts" "src/**/*.jsx" "src/**/*.tsx" "public/**/*.html" )

# Build a list of files to scan
mapfile -t files < <(find src -type f \( -name '*.astro' -o -name '*.md' -o -name '*.html' -o -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' \) 2>/dev/null || true)

# Also scan top-level files that might contain links
if [ -d public ]; then
  mapfile -t pubfiles < <(find public -type f \( -name '*.html' -o -name '*.htm' \) 2>/dev/null || true)
  files+=( "${pubfiles[@]}" )
fi

# If no files found, exit
if [ ${#files[@]} -eq 0 ]; then
  echo "No target files found under src/ or public/ to scan. Exiting."
  exit 0
fi

echo "Scanning ${#files[@]} files for absolute-root src/href occurrences (this may take a moment)..."
echo

# Preview: print file:line:snippet for occurrences
# The perl pattern looks for (src|href)=['"]/<not allowed prefixes>
# It excludes:
#  - already prefixed /eromosele.edeko/
#  - http(s):
#  - anchors (#)
#  - mailto:
#  - tel:
perl -nle 'if (/(?:\b(?:src|href))=(["\'])\/(?!eromosele\.edeko\/|https?:|#|mailto:|tel:)/) { print "$ARGV:$.: $_" }' "${files[@]}" | sed -n '1,200p' || true

# Count matches
MATCH_COUNT=$(perl -nle 'BEGIN{$c=0} $c++ if (/(?:\b(?:src|href))=(["\'])\/(?!eromosele\.edeko\/|https?:|#|mailto:|tel:)/); END{print $c}' "${files[@]}")

echo
echo "Found ${MATCH_COUNT} matching lines across files."
if [ "$MATCH_COUNT" -eq 0 ]; then
  echo "Nothing to replace. Exiting."
  exit 0
fi

if [ "$AUTO_YES" = false ]; then
  read -p "Proceed to create branch ${BRANCH}, replace matches and commit? (y/N) " yn
  case "$yn" in
    [Yy]*) AUTO_YES=true ;;
    *) echo "Aborted by user."; exit 0 ;;
  esac
fi

echo "Creating branch ${BRANCH}..."
git checkout -b "${BRANCH}"

echo "Applying replacements (backups will be created with .bak extension where modified)..."

# Replacement logic:
# - Finds occurrences of (src|href)=(" or ') /some/path
# - Ignores already /eromosele.edeko/**, http(s) links, anchors (#), mailto:, tel:
# - Replaces with (src|href)=["'] /eromosele.edeko/some/path
#
# Use perl in-place with a backup extension so you can inspect original files if needed.
perl -0777 -i.bak -pe '
  s{(\b(?:src|href)=)(["\'])\/(?!eromosele\.edeko\/|https?:|#|mailto:|tel:)(.*?)(\2)}{$1$2/eromosele.edeko/$3$4}gs;
' "${files[@]}"

# Remove any empty .bak files if no changes were made for a particular file
find . -type f -name "*.bak" -size 0 -delete || true

echo "Showing a short summary of changed files:"
git add -A
git status --porcelain | sed -n '1,200p'

echo
echo "Git diff (files and hunks):"
git --no-pager diff --staged | sed -n '1,200p' || true

read -p "Commit these changes to branch ${BRANCH}? (y/N) " yn2
case "$yn2" in
  [Yy]*)
    git commit -m "Fix absolute-root src/href paths to include /${REPO_BASE}/ for GitHub Pages"
    echo "Pushing branch ${BRANCH} to origin..."
    git push -u origin "${BRANCH}"
    ;;
  *)
    echo "No commit made. You can inspect changes and commit manually. Exiting."
    exit 0
    ;;
esac

if [ "${DO_PUBLISH}" = true ]; then
  if [ -x ./publish_local.sh ]; then
    echo "Running ./publish_local.sh to rebuild and publish..."
    ./publish_local.sh --yes
  else
    echo "publish_local.sh not found or not executable. Skipping publish step."
  fi
fi

echo
echo "Done. Branch ${BRANCH} pushed with replacements."
echo "Next: review the branch on GitHub, run tests/build locally, then merge to main when ready."
