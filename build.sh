#!/bin/bash

# Build script for Sentinel
# This script builds the Sentinel app using Swift Package Manager

set -e

echo "🛡️  Building Sentinel..."
echo ""

# Change to the script directory
cd "$(dirname "$0")"

# Clean previous builds (optional)
if [ "$1" == "clean" ]; then
    echo "🧹 Cleaning previous builds..."
    rm -rf .build
    echo "✅ Clean complete"
    echo ""
fi

# Build in release mode
echo "🔨 Building release binary..."
swift build -c release

echo ""
echo "✅ Build complete!"
echo ""
echo "Binary location: .build/release/Sentinel"
echo ""
echo "To run Sentinel:"
echo "  ./.build/release/Sentinel"
echo ""
echo "To install to Applications:"
echo "  ./install.sh"
