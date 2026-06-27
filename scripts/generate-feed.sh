#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assume the project root is one level above (scripts/ is inside the root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Define directories (absolute paths)
SRC_DIR="${PROJECT_ROOT}/src"
BOOK_DIR="${PROJECT_ROOT}/book"
OUTPUT_FILE="${SRC_DIR}/feed.xml"

# Configuration variables (can be overridden by environment)
FEED_TITLE="${FEED_TITLE:-My Podcast}"
SITE_URL="${SITE_URL:-https://meusite.com}"
FEED_DESCRIPTION="${FEED_DESCRIPTION:-An awesome podcast}"

echo "📡 Generating RSS feed at: $OUTPUT_FILE"
echo "   Title: $FEED_TITLE"
echo "   URL: $SITE_URL"

# Supported audio extensions (priority order)
AUDIO_EXTS=("mp3" "m4a" "ogg" "wav")

# Function to map extension to MIME type
get_mime_type() {
    case "$1" in
        mp3) echo "audio/mpeg" ;;
        m4a) echo "audio/mp4" ;;
        ogg) echo "audio/ogg" ;;
        wav) echo "audio/wav" ;;
        *)   echo "application/octet-stream" ;;
    esac
}

# Generate RSS header with podcast namespaces
cat > "$OUTPUT_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0"
    xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
<channel>
<title>${FEED_TITLE}</title>
<link>${SITE_URL}</link>
<description>${FEED_DESCRIPTION}</description>
EOF

# Collect markdown files:
# 1) Must start with YYYY-MM-DD-
# 2) Must NOT be Template.md
files=()
while IFS= read -r -d '' file; do
    basename_f=$(basename "$file")
    if [[ "$basename_f" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+\.md$ ]] && [[ ! "$basename_f" == *Template.md ]]; then
        files+=("$basename_f")
    fi
done < <(find "$SRC_DIR" -maxdepth 1 -type f -name "*.md" ! -name "SUMMARY.md" -print0)

# Sort descending (newest first)
IFS=$'\n' files=($(sort -r <<<"${files[*]}"))
unset IFS

echo "📄 Found ${#files[@]} posts for feed."

# Generate RSS items
for filename in "${files[@]}"; do
    filepath="$SRC_DIR/$filename"
    base="${filename%.md}"

    filedate="${filename:0:10}"
    day="${filedate:8:2}"
    month="${filedate:5:2}"
    year="${filedate:0:4}"

    # Convert month to English abbreviation (RFC 2822)
    case $month in
        01) mon="Jan";; 02) mon="Feb";; 03) mon="Mar";;
        04) mon="Apr";; 05) mon="May";; 06) mon="Jun";;
        07) mon="Jul";; 08) mon="Aug";; 09) mon="Sep";;
        10) mon="Oct";; 11) mon="Nov";; 12) mon="Dec";;
        *)  mon="Jan" ;;
    esac

    pubdate="${day} ${mon} ${year} 00:00:00 +0000"

    # Title extraction
    title=$(sed -n 's/^# //p;q' "$filepath" 2>/dev/null)
    if [ -z "$title" ]; then
        title="${filename:11}"
        title="${title%.md}"
        title="${title//_/ }"
    fi

    # Link
    link="${SITE_URL}/${base}.html"

    # Content cleanup
    filtered_content=$(sed -e '1{/^# /d}' -e '/^######/d' -e '/&nbsp;<br>/d' -e '/^[[:space:]]*$/d' "$filepath")
    escaped_content=$(echo "$filtered_content" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    # Audio detection
    audio_url=""
    audio_length=""
    audio_type=""
    audio_duration=""

    for ext in "${AUDIO_EXTS[@]}"; do
        audio_file="$SRC_DIR/$base.$ext"
        if [[ -f "$audio_file" ]]; then
            audio_url="${SITE_URL}/${base}.${ext}"
            audio_length=$(stat -c %s "$audio_file" 2>/dev/null || stat -f %z "$audio_file" 2>/dev/null)
            audio_type=$(get_mime_type "$ext")

            if command -v ffprobe &> /dev/null; then
                audio_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio_file" 2>/dev/null | cut -d. -f1)
            fi
            break
        fi
    done

    # Write item
    cat >> "$OUTPUT_FILE" <<ITEM
<item>
<title>${title}</title>
<link>${link}</link>
<pubDate>${pubdate}</pubDate>
<description>${escaped_content}</description>
ITEM

    # Optional enclosure
    if [[ -n "$audio_url" ]]; then
        cat >> "$OUTPUT_FILE" <<ENC
<enclosure url="${audio_url}" length="${audio_length}" type="${audio_type}"/>
ENC

        if [[ -n "$audio_duration" ]]; then
            cat >> "$OUTPUT_FILE" <<DUR
<itunes:duration>${audio_duration}</itunes:duration>
DUR
        fi
    fi

    echo "</item>" >> "$OUTPUT_FILE"
done

# Close RSS
cat >> "$OUTPUT_FILE" <<EOF
</channel>
</rss>
EOF

# Copy feed to book directory for publishing
echo "📁 Copying feed to ${BOOK_DIR}/feed.xml"
cp "$OUTPUT_FILE" "${BOOK_DIR}/feed.xml"

echo "✅ Feed generated successfully at: $OUTPUT_FILE"