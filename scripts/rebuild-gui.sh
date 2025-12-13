#!/bin/bash
# File: /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/scripts/rebuild-gui.sh
# Description: Rebuild the DevManagement application for development
# Author: Libor Ballaty <libor@arionetworks.com>
# Created: 2025-12-13
#
# Business Purpose: Provides a consistent development workflow for testing GUI changes.
# The Swift compiler and MenuBarExtra require clean rebuilds to pick up changes.
#
# Usage: ./scripts/rebuild-gui.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"

echo "🔨 Rebuilding DevManagement..."
echo ""

# Kill any running instances
echo "Killing existing instances..."
killall "dev-manager" 2>/dev/null || true
sleep 1

# Clean previous build
echo "Cleaning previous build..."
rm -rf "${BUILD_DIR}"

# Build the project
echo "Building application..."
cd "${PROJECT_ROOT}"
swift build

# Show build result
echo ""
echo "✅ Build complete"
echo ""
echo "📍 Application location:"
echo "   ${BUILD_DIR}/debug/dev-manager"
echo ""
echo "To test the CLI:"
echo "   ${BUILD_DIR}/debug/dev-manager status"
