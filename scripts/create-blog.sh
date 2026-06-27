#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assume the project root is one level above (scripts/ is inside the project root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Define file paths (relative to the project root)
BOOK_DIR="${PROJECT_ROOT}/book"
INPUT_FILE="${BOOK_DIR}/print.html"
OUTPUT_FILE="${BOOK_DIR}/blog.html"

echo "📄 Creating blog.html from print.html..."
cp "$INPUT_FILE" "$OUTPUT_FILE"

# Remove the automatic print script block
echo "🧹 Removing automatic print scripts..."
sed -i '/<script>/,/<\/script>/ {
    /window\.print/d
    /window\.addEventListener/d
    /window\.setTimeout/d
}' "$OUTPUT_FILE"

# Remove a specific script block with Perl (in case sed doesn't catch everything)
perl -i -0pe 's/\s*window\.addEventListener('"'"'load'"'"',\s*function\s*\(\)\s*\{\s*window\.setTimeout\(window\.print,\s*100\s*\);\s*\}\s*\);\s*<\/script>//gis' "$OUTPUT_FILE"

# Replace the print script with one that disables window.print
sed -i 's|</head>|<script>window.print = function() { return false; };</script></head>|' "$OUTPUT_FILE"

# Remove the table of contents section from blog.html
echo "📖 Removing the table of contents page from blog.html..."
sed -i '/<div id="summary">/,/<\/div>/d' "$OUTPUT_FILE"
sed -i '/<h1>Table of Contents<\/h1>/,/<\/div>/d' "$OUTPUT_FILE"

echo "✅ Done! The file has been generated at ${OUTPUT_FILE}"