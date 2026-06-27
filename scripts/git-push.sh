#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assume the project root is one level above (scripts/ is inside the root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BOOK_DIR="${PROJECT_ROOT}/book"

echo "📤 Committing changes in the main repository"

# Move to project root so git commands work correctly
cd "$PROJECT_ROOT"

git pull

if [ -n "$(git status --porcelain)" ]; then
    git add .
    commit_date=$(date '+%Y-%m-%d %H:%M:%S')
    changed_files=$(git diff --cached --name-only)

    git commit -m "Automatic update at $commit_date

Changed files:
$changed_files"

    echo "📤 Pushing commit to remote..."
    git push origin HEAD
else
    echo "ℹ️ No changes to commit."
fi

echo "🚀 Deploying to gh-pages..."

# Create temporary directory for deployment
TMP_DIR=$(mktemp -d -t gh-pages-deploy-XXXXXX)

# Ensure cleanup on exit
trap 'rm -rf "$TMP_DIR"' EXIT

# Copy build output to temp directory
cp -r "$BOOK_DIR"/* "$TMP_DIR/"

# Initialize gh-pages repo
cd "$TMP_DIR"
git init
git checkout -b gh-pages
git add .
git commit -m "Site deploy - $(date '+%Y-%m-%d %H:%M:%S')"
git remote add origin git@github.com:"$GITHUB_PROJECT"
git push origin gh-pages --force

# Return to previous directory
cd - > /dev/null

echo "✅ Deploy completed successfully!"
