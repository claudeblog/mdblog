#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assume the project root is one level above (scripts/ is inside the root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source directory (absolute path)
SRC_DIR="${PROJECT_ROOT}/src"

if [ ! -d "$SRC_DIR" ]; then
    echo "❌ Error: Directory $SRC_DIR not found."
    exit 1
fi

echo "📂 Processing files in: $SRC_DIR"
cd "$SRC_DIR"

for file in *.md; do
    [ -f "$file" ] || continue

    # Extract date from filename (YYYY-MM-DD-)
    if [[ ! "$file" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})- ]]; then
        echo "⚠️  Warning: $file does not start with YYYY-MM-DD, skipping."
        continue
    fi
    date="${BASH_REMATCH[1]}"

    # Extract title (first line starting with '# ')
    raw_title=$(grep -m 1 '^# ' "$file" | sed 's/^# //' | sed 's/^[[:space:]]*//' || true)

    if [ -z "$raw_title" ]; then
        echo "⚠️  Warning: $file has no # Title header, skipping."
        continue
    fi

    # If title contains a hyphen, keep only the part after the first hyphen
    if [[ "$raw_title" == *-* ]]; then
        cleaned_title="${raw_title#*-}"
        cleaned_title="${cleaned_title## }"
    else
        cleaned_title="$raw_title"
    fi

    # Remove punctuation and convert spaces to underscores
    slug=$(echo "$cleaned_title" |
        tr -d '[:punct:]' |
        tr ' ' '_' |
        sed 's/_\+/_/g' |
        sed 's/^_//;s/_$//')

    newname="${date}-${slug}.md"

    if [ "$file" = "$newname" ]; then
        continue
    fi

    if [ -e "$newname" ]; then
        echo "❌ Error: $newname already exists, cannot rename $file"
        continue
    fi

    echo "🔄 Renaming: $file -> $newname"
    mv -- "$file" "$newname"

done

echo "✅ Renaming completed!"