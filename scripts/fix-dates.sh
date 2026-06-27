#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assume the project root is one level above (scripts/ is inside the project root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Directory containing the Markdown files (using an absolute path)
TARGET_DIR="${PROJECT_ROOT}/src"

echo "📂 Processing .md files in ${TARGET_DIR}..."

find "$TARGET_DIR" -maxdepth 1 -type f -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md" | while read -r file; do
    filename=$(basename "$file")

    # Extract YYYY-MM-DD (first 10 characters) and convert it to DD/MM/YYYY
    date_part="${filename:0:10}"
    year="${date_part:0:4}"
    month="${date_part:5:2}"
    day="${date_part:8:2}"
    formatted_date="$day/$month/$year"

    tmp_file=$(mktemp)

    echo "   Processing: $filename -> date $formatted_date"

    awk -v newdate="$formatted_date" '
    # Remove any line that is exactly "###### *DD/MM/YYYY*" (allowing optional trailing spaces)
    /^###### \*[0-9]{2}\/[0-9]{2}\/[0-9]{4}\*\s*$/ { next }

    # Store all remaining lines in an array
    { lines[++n] = $0 }

    END {
        # Print all lines except the previous date line
        for (i = 1; i <= n; i++) {
            print lines[i]
        }

        # Add a blank line only if the last printed line is not already blank
        if (n > 0 && lines[n] != "") {
            print ""
        }

        # Append the new date at the end
        print "###### *" newdate "*"
    }' "$file" > "$tmp_file"

    mv "$tmp_file" "$file"

done