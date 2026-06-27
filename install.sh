#!/bin/bash
set -e

# ----------------------------------------------------------------------
# Check whether the .env file exists
# ----------------------------------------------------------------------
if [ ! -f .env ]; then
    echo "❌ .env file not found. Create a .env file with the required configuration."
    exit 1
fi

echo "📄 Loading .env file..."
set -a
. .env
set +a

# ----------------------------------------------------------------------
# Generate book.toml from the .env variables
# ----------------------------------------------------------------------
echo "📝 Generating book.toml..."
cat > book.toml <<EOF
[book]
title = "$BOOK_TITLE"
authors = ["$BOOK_AUTHORS"]
language = "$BOOK_LANGUAGE"

[output.html]
default-theme = "$OUTPUT_HTML_DEFAULT_THEME"
preferred-dark-theme = "$OUTPUT_HTML_PREFERRED_DARK_THEME"
EOF

echo "✅ book.toml created successfully."

# ----------------------------------------------------------------------
# Install project prerequisites
# ----------------------------------------------------------------------
echo "🔧 Installing prerequisites for the mdBook project..."

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "⚠️ Unable to detect the Linux distribution."
    exit 1
fi

# Function to install required packages
install_packages() {
    case "$DISTRO" in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y git curl build-essential ffmpeg
            ;;
        fedora)
            sudo dnf install -y git curl @development-tools ffmpeg
            ;;
        *)
            echo "⚠️ Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
}

install_packages

# Install Rust if necessary
if ! command -v rustc &> /dev/null; then
    echo "🦀 Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Load Rust/Cargo into the current shell
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

export PATH="$HOME/.cargo/bin:$PATH"

# Install mdBook
if ! command -v mdbook &> /dev/null; then
    echo "📚 Installing mdBook..."
    cargo install mdbook
else
    echo "✅ mdBook is already installed."
fi

# Permanently add ~/.cargo/bin to PATH
if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    echo "➕ PATH updated in ~/.bashrc"
fi

# ----------------------------------------------------------------------
# Grant execution permission to all existing .sh scripts
# ----------------------------------------------------------------------
echo "🔑 Granting execution permissions to .sh scripts..."

# List of expected scripts
scripts=(
    "fix-dates.sh"
    "fix-line-breaks.sh"
    "update-summary.sh"
    "template.sh"
    "rename-files.sh"
    "create-blog.sh"
    "generate-feed.sh"
    "git-push.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "scripts/$script"
        echo "   ✔ $script"
    else
        echo "   ⚠️ $script not found – skipped."
    fi
done

chmod +x "publish.sh"

# ----------------------------------------------------------------------
# Check whether ffprobe is available
# ----------------------------------------------------------------------
if command -v ffprobe &> /dev/null; then
    echo "✅ ffprobe is installed – the RSS feed will be able to include audio durations."
else
    echo "⚠️ ffprobe not found. Audio durations will not be added to the RSS feed."
    echo "   Try restarting your terminal or installing FFmpeg manually."
fi

echo "🎉 Installation complete!"
echo "Use ./publish.sh to update SUMMARY.md, fix line breaks, commit changes, and publish the site."