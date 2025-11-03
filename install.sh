#!/bin/bash

# Installation script for Sentinel
# This script copies the built binary to Applications and sets up the app bundle

set -e

echo "🛡️  Installing Sentinel..."
echo ""

# Change to the script directory
cd "$(dirname "$0")"

# Check if the binary exists
if [ ! -f ".build/release/Sentinel" ]; then
    echo "❌ Error: Sentinel binary not found. Please run ./build.sh first"
    exit 1
fi

# Create app bundle structure
APP_DIR="/Applications/Sentinel.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating app bundle..."
sudo mkdir -p "$MACOS_DIR"
sudo mkdir -p "$RESOURCES_DIR"

# Copy binary
echo "📋 Copying binary..."
sudo cp .build/release/Sentinel "$MACOS_DIR/"
sudo chmod +x "$MACOS_DIR/Sentinel"

# Copy and fix Info.plist
echo "📋 Copying Info.plist..."
cp sentinel/Info.plist /tmp/Sentinel-Info.plist
sed -i '' 's/$(EXECUTABLE_NAME)/Sentinel/g' /tmp/Sentinel-Info.plist
sed -i '' 's/$(PRODUCT_BUNDLE_IDENTIFIER)/com.sentinel.app/g' /tmp/Sentinel-Info.plist
sed -i '' 's/$(DEVELOPMENT_LANGUAGE)/en/g' /tmp/Sentinel-Info.plist
sed -i '' 's/$(PRODUCT_NAME)/Sentinel/g' /tmp/Sentinel-Info.plist
sed -i '' 's/$(PRODUCT_BUNDLE_PACKAGE_TYPE)/APPL/g' /tmp/Sentinel-Info.plist
sed -i '' 's/$(MACOSX_DEPLOYMENT_TARGET)/13.0/g' /tmp/Sentinel-Info.plist
sudo cp /tmp/Sentinel-Info.plist "$CONTENTS_DIR/Info.plist"

# Copy resources (if they exist)
echo "📋 Copying resources..."
if [ -f ".build/release/Sentinel_Sentinel.bundle/Contents/Resources/example-hooks.json" ]; then
    sudo cp .build/release/Sentinel_Sentinel.bundle/Contents/Resources/example-hooks.json "$RESOURCES_DIR/"
elif [ -f "sentinel/Resources/example-hooks.json" ]; then
    sudo cp sentinel/Resources/example-hooks.json "$RESOURCES_DIR/"
fi

# Create a simple icon (optional - can be improved)
echo "🎨 Setting up icon..."
# Using system shield icon as placeholder
# In production, you'd create a proper .icns file

echo ""
echo "✅ Installation complete!"
echo ""
echo "Sentinel has been installed to: $APP_DIR"
echo ""
echo "To launch Sentinel:"
echo "  open /Applications/Sentinel.app"
echo ""
echo "Next steps:"
echo "  1. Launch Sentinel from Applications"
echo "  2. Configure Claude Code hooks by manually editing ~/.claude/settings.json"
echo "     Add the hooks configuration from Sentinel/Resources/example-hooks.json"
echo "     to the 'hooks' property in your settings file."
echo "  3. Start using Claude Code and watch Sentinel monitor your sessions!"
