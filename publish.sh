#!/bin/bash
set -e

echo "Loading .env file..."
set -a
. .env
set +a

export PATH="$HOME/.cargo/bin:$PATH"

echo "🏷️ Renaming .md files based on their titles..."
./scripts/rename-files.sh

echo "🔄 Updating SUMMARY.md..."
./scripts/update-summary.sh

echo "📅 Fixing dates inside blockquotes..."
./scripts/fix-dates.sh

echo "✍️ Fixing line breaks in .md files..."
./scripts/fix-line-breaks.sh

echo "📚 Building the website with mdBook..."
rm -rf book/
mdbook build

echo "📄 Creating blog.html for continuous reading..."
./scripts/create-blog.sh

echo "📡 Generating the RSS feed..."
./scripts/generate-feed.sh

echo "🌐 Configuring custom domain: $DOMAIN"
echo "$DOMAIN" > book/CNAME
echo "$DOMAIN" > CNAME

echo "✍️ Generating templates..."
./scripts/template.sh || true

echo "📤 Committing changes to the main repository..."
./scripts/git-push.sh

echo "✅ Publishing completed: $DOMAIN"