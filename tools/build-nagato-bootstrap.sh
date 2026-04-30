#!/bin/bash
# ==============================================================================
# build-nagato-bootstrap.sh
# Builds a custom bootstrap for com.nagato.agent on aarch64.
# Run inside nagato-packages/ directory.
# ==============================================================================
set -euo pipefail

ARCH="aarch64"
BOOTSTRAP_OUT="bootstrap-${ARCH}.zip"

# Optional extra packages to include beyond the default base
EXTRA_PACKAGES="python,python-pip,git,nodejs,openssl"

echo "===================================================================="
echo "Nagato Bootstrap Builder"
echo "Architecture: ${ARCH}"
echo "Extra packages: ${EXTRA_PACKAGES}"
echo "===================================================================="

# Verify we are in termux-packages root
if [ ! -f "scripts/properties.sh" ]; then
    echo "Error: Must run from nagato-packages root directory."
    echo "       scripts/properties.sh not found."
    exit 1
fi

echo ""
echo "[1/4] Verifying properties.sh has correct package name..."
PKG_NAME=$(grep "TERMUX_APP__PACKAGE_NAME" scripts/properties.sh | head -1)
echo "    Found: ${PKG_NAME}"
if echo "$PKG_NAME" | grep -q "com.termux"; then
    echo "WARNING: properties.sh still references com.termux!"
    echo "         Run tools/setup-nagato-fork.sh first."
    read -p "Continue anyway? (y/N) " yn
    [ "$yn" = "y" ] || exit 1
fi

echo ""
echo "[2/4] Checking for build-bootstraps.sh..."
if [ ! -f "scripts/build-bootstraps.sh" ]; then
    echo "    build-bootstraps.sh not found. Downloading from upstream..."
    curl -sL "https://raw.githubusercontent.com/termux/termux-packages/master/scripts/build-bootstraps.sh"          -o scripts/build-bootstraps.sh
    chmod +x scripts/build-bootstraps.sh
    echo "    Downloaded."
else
    echo "    build-bootstraps.sh already present."
fi

echo ""
echo "[3/4] Building bootstrap (this takes several hours)..."
echo "    If Docker is available, run:"
echo "      ./scripts/run-docker.sh ./scripts/build-bootstraps.sh --architectures ${ARCH}"
echo ""

# Check if Docker is available
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo "    Docker detected. Starting Docker build..."
    docker run --rm -it \
        -v "$(pwd):/home/builder/termux-packages" \
        termux/package-builder:latest \
        bash -c "cd termux-packages && ./scripts/build-bootstraps.sh --architectures ${ARCH}"
else
    echo "    Docker not available. Attempting native build (requires NDK + LLVM)..."
    if [ -z "${ANDROID_NDK_HOME}" ]; then
        echo "Error: ANDROID_NDK_HOME not set. Install Android NDK first."
        exit 1
    fi
    ./scripts/build-bootstraps.sh --architectures "${ARCH}"
fi

echo ""
echo "[4/4] Packaging result..."
if [ -f "${BOOTSTRAP_OUT}" ]; then
    echo "    SUCCESS: ${BOOTSTRAP_OUT} built ($(du -h "${BOOTSTRAP_OUT}" | cut -f1))"
    echo ""
    echo "    Next steps:"
    echo "    1. Copy ${BOOTSTRAP_OUT} to nagato-android/app/src/main/cpp/"
    echo "    2. Update app/build.gradle to disable downloadBootstraps"
    echo "    3. Build APK: cd nagato-android && ./gradlew assembleDebug"
else
    echo "    ERROR: ${BOOTSTRAP_OUT} was not created."
    echo "    Check Docker logs for errors."
    exit 1
fi
