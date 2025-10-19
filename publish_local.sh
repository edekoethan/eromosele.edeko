#!/usr/bin/env bash
# publish_local.sh
# Build the Astro site, update astro.config.mjs for GitHub Pages,
# move the build output into docs/, optionally add a Pages deploy workflow,
# and push the changes to origin/main.
#
# Usage:
#   ./publish_local.sh        # quick local publish to main:/docs
#   ./publish_local.sh --ci   # also create GitHub Actions workflow to auto-deploy

set -euo pipefail

BRANCH="main"
SITE="https://edekoethan.github.io/eromosele.edeko"
BASE="/eromosele.edeko/"
WORKFLOW_PATH=".github/workflows/deploy-pages.yml"

echo "1) Ensuring we're on branch ${BRANCH} and up-to-date"
git checkout "${BRANCH}"
git pull origin "${BRANCH}"

echo "2) Backing up existing astro.config.mjs (if present)"
if [ -f astro.config.mjs ]; then
  cp astro.config.mjs astro.config.mjs.bak
  echo "  - backup created: astro.config.mjs.bak"
fi

echo "3) Writing updated astro.config.mjs (sets site and base for GH Pages)"
cat > astro.config.mjs <<'EOF'
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import tailwind from "@astrojs/tailwind";

// https://astro.build/config
export default defineConfig({
  site: 'https://edekoethan.github.io/eromosele.edeko',
  base: '/eromosele.edeko/',
  integrations: [mdx(), sitemap(), tailwind()]
});
EOF

# Commit astro.config change if any
git add astro.config.mjs
if git diff --cached --quiet; then
  echo "  - No changes to commit for astro.config.mjs"
else
  git commit -m "Set Astro base and site for GitHub Pages"
fi

echo "4) Installing dependencies and building site"
# prefer npm ci for clean reproducible installs; fallback to npm install if ci fails
if npm ci --no-audit --no-fund 2>/dev/null; then
  echo "  - npm ci completed"
else
  echo "  - npm ci failed, trying npm install"
  npm install
fi
npm run build

if [ ! -d dist ]; then
  echo "ERROR: build did not produce a 'dist' directory. Aborting."
  exit 1
fi

echo "5) Publishing build into docs/ for GitHub Pages"
rm -rf docs
mkdir -p docs

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete dist/ docs/
else
  # cp -a preserves attributes; in Git Bash cp -a should work
  cp -a dist/. docs/
fi

# Ensure .nojekyll so GH Pages doesn't strip _astro or similar directories
touch docs/.nojekyll

git add docs
if git diff --cached --quiet; then
  echo "  - No changes to commit for docs (build identical to what's committed)"
else
  git commit -m "Publish site: add build output to docs"
fi

echo "6) Optionally add GitHub Actions deploy workflow (pass --ci to create it)"
CREATE_CI=false
if [ "${1:-}" = "--ci" ] || [ "${2:-}" = "--ci" ]; then
  CREATE_CI=true
fi

if [ "${CREATE_CI}" = true ]; then
  echo "  - Creating ${WORKFLOW_PATH}"
  mkdir -p "$(dirname "${WORKFLOW_PATH}")"
  cat > "${WORKFLOW_PATH}" <<'EOF'
name: Build and deploy to GitHub Pages

on:
  push:
    branches:
      - main

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install dependencies
        run: npm ci
      - name: Build site
        run: npm run build
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v1
        with:
          path: ./dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        uses: actions/deploy-pages@v1
EOF

  git add "${WORKFLOW_PATH}"
  if git diff --cached --quiet; then
    echo "  - No changes to commit for workflow"
  else
    git commit -m "Add Pages deploy workflow"
  fi
fi

echo "7) Pushing commits to origin/${BRANCH}"
git push origin "${BRANCH}"

echo "Done. If you didn't create the workflow, go to Settings → Pages and set Source = branch 'main' and Folder = '/docs'."
echo "Open: https://edekoethan.github.io/eromosele.edeko/ (allow ~1-2 minutes for Pages to publish)"
