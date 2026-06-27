#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assume the project root is one level above (scripts/ is inside the root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📚 Generating SUMMARY.md at: $PROJECT_ROOT/src"

# Move to project root so relative paths work
cd "$PROJECT_ROOT"

SUMMARY_FILE="src/SUMMARY.md"
TMP_SUMMARY=$(mktemp)

# Clear file (will be overwritten)
> "$SUMMARY_FILE"

# Header
cat > "$TMP_SUMMARY" << 'HEAD'
# Summary
HEAD

# Collect markdown files excluding special ones
files=()
for file in src/*.md; do
    [ -f "$file" ] || continue
    basename=$(basename "$file")

    # Ignore special pages and files with spaces
    [[ "$basename" =~ ^(README|SUMMARY|About|Cover|RSS)\.md$ ]] && continue
    [[ "$basename" =~ \  ]] && { echo "⚠️ Skipping file with space: $basename"; continue; }

    # Ignore templates
    [[ "$basename" =~ Template\.md$ ]] && continue

    files+=("$file")
done

extract_date() {
    local filename=$(basename "$1")
    [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]] && echo "${BASH_REMATCH[1]}" || echo "0000-00-00"
}

IFS=$'\n' sorted_files=($(for f in "${files[@]}"; do
    echo "$(extract_date "$f") $f"
done | sort -r | awk '{print $2}'))

for file in "${sorted_files[@]}"; do
    basename=$(basename "$file" .md)

    if [[ "$basename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]]; then
        title_part="${BASH_REMATCH[2]}"
    else
        title_part="$basename"
    fi

    title=$(echo "$title_part" | sed 's/_/ /g; s/-/ /g; s/ +/ /g')
    rel_path=$(echo "$file" | sed 's|src/||')

    echo "- [$title]($rel_path)" >> "$TMP_SUMMARY"
done

# Add special pages at the end
echo "- [Summary](SUMMARY.md)" >> "$TMP_SUMMARY"

[ -f "src/About.md" ] && echo "- [About](About.md)" >> "$TMP_SUMMARY"
[ -f "src/RSS.md" ] && echo "- [RSS Feed](RSS.md)" >> "$TMP_SUMMARY"
[ -f "src/Cover.md" ] && echo "- [Cover](Cover.md)" >> "$TMP_SUMMARY"

# Write final file
cat "$TMP_SUMMARY" > "$SUMMARY_FILE"
rm -f "$TMP_SUMMARY"

echo "✅ SUMMARY.md generated successfully!"