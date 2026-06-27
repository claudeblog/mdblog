#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assume the project root is one level above (scripts/ is inside the root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Destination directory (absolute path)
SRC_DIR="${PROJECT_ROOT}/src"

# Current date in YYYY-MM-DD format
DATE=$(date +%Y-%m-%d)
FILENAME="${SRC_DIR}/${DATE}-Template.md"

echo "📝 Creating new template at: $FILENAME"

# Template content
read -r -d '' CONTENT << EOF || true

# Template

Lorem ipsum dolor sit amet,
consectetur adipiscing elit,
sed do eiusmod tempor incididunt ut labore
et dolore magna aliqua. Ut enim ad minim veniam,

quis nostrud exercitation ullamco laboris
nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit
in voluptate velit esse cillum dolore

eu fugiat nulla pariatur.
Excepteur sint occaecat
cupidatat non proident,
sunt in culpa qui officia

deserunt mollit anim id est laborum.

###### *$(date +%d/%m/%Y)*

EOF

# Check if file already exists
if [ -e "$FILENAME" ]; then
    echo "❌ Error: File $FILENAME already exists."
    exit 1
fi

# Create file
echo "$CONTENT" > "$FILENAME"

echo "✅ Template created successfully: $FILENAME"