#!/bin/bash
# Build script for MacPad++ on macOS
# Usage: ./build_mac.sh [debug|release] [clean]
#
# Prerequisites:
#   - Xcode Command Line Tools: xcode-select --install
#   - CMake: brew install cmake
#
# The script builds a self-contained MacPad++.app in build/MacPadPlusPlus/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TYPE="${1:-Release}"
CLEAN="${2:-}"
BUILD_DIR="${SCRIPT_DIR}/build"
APP_BUILD_DIR="${BUILD_DIR}/MacPadPlusPlus"
INSTALL_DIR="${BUILD_DIR}/dist"

# Normalize build type
case "${BUILD_TYPE,,}" in
    debug)   CMAKE_BUILD_TYPE="Debug" ;;
    release) CMAKE_BUILD_TYPE="Release" ;;
    *)       CMAKE_BUILD_TYPE="Release" ;;
esac

echo "======================================================"
echo "  MacPad++ macOS Build"
echo "  Build type: ${CMAKE_BUILD_TYPE}"
echo "  Source:     ${SCRIPT_DIR}"
echo "  Build dir:  ${APP_BUILD_DIR}"
echo "======================================================"

# Check prerequisites
if ! command -v cmake &>/dev/null; then
    echo "ERROR: cmake not found."
    echo "Install with: brew install cmake"
    exit 1
fi

if ! xcode-select -p &>/dev/null; then
    echo "ERROR: Xcode Command Line Tools not found."
    echo "Install with: xcode-select --install"
    exit 1
fi

echo "CMake: $(cmake --version | head -1)"
echo "Xcode: $(xcode-select -p)"
echo "macOS: $(sw_vers -productVersion)"
echo ""

# Clean if requested
if [ "${CLEAN}" = "clean" ] || [ "${BUILD_TYPE}" = "clean" ]; then
    echo "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
fi

# Create build directory
mkdir -p "${APP_BUILD_DIR}"

# Configure
echo "Configuring with CMake..."
cmake \
    -S "${SCRIPT_DIR}" \
    -B "${APP_BUILD_DIR}" \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
    -DCMAKE_OSX_ARCHITECTURES="$(uname -m)" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"

echo ""
echo "Building MacPad++..."
cmake --build "${APP_BUILD_DIR}" --config "${CMAKE_BUILD_TYPE}" -- -j$(sysctl -n hw.ncpu)

echo ""
APP_PATH="${APP_BUILD_DIR}/MacPadPlusPlus.app"
if [ -d "${APP_PATH}" ]; then
    echo "======================================================"
    echo "  Build SUCCESSFUL!"
    echo "  App: ${APP_PATH}"
    echo ""
    echo "  To run:"
    echo "    open '${APP_PATH}'"
    echo ""
    echo "  To install to /Applications:"
    echo "    cp -r '${APP_PATH}' /Applications/"
    echo "======================================================"

    # Optionally open the app
    if [ "${3}" = "run" ]; then
        echo "Opening MacPad++..."
        open "${APP_PATH}"
    fi
else
    echo "ERROR: App bundle not found at ${APP_PATH}"
    exit 1
fi
