#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
IMAGE_NAME="debian-toolbox-dev:12-0.1"
CONTAINERFILE="Containerfile"
# This script is expected to set up the user's local bin directory in PATH.
SETUP_LOCAL_PATH_SCRIPT="./setup_local_path.sh"
# Assumes test_image.sh is in the same directory and is executable.
TEST_SCRIPT="./test_image_base.sh"

# --- Prerequisite Checks ---
# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo "Error: Podman is not installed. Please install Podman to build the image."
    echo "More info: https://podman.io/docs/installation"
    exit 1
fi

# Check if Toolbox is installed (as test_image.sh might use it)
if ! command -v toolbox &> /dev/null; then
    echo "Error: toolbox is not installed. The test script might require it."
    echo "More info: https://containertoolbx.org/"
    exit 1
fi

# Check if the Containerfile exists
if [ ! -f "$CONTAINERFILE" ]; then
    echo "Error: Containerfile ($CONTAINERFILE) not found in the current directory."
    exit 1
fi

# Check if the test script exists and is executable
if [ ! -f "$TEST_SCRIPT" ]; then
    echo "Error: Test script ($TEST_SCRIPT) not found."
    exit 1
fi
if [ ! -x "$TEST_SCRIPT" ]; then
    echo "Error: Test script ($TEST_SCRIPT) is not executable. Please run: chmod +x $TEST_SCRIPT"
    exit 1
fi

# --- Build Step ---
echo ">>> Building image: $IMAGE_NAME using $CONTAINERFILE..."
podman build -t "$IMAGE_NAME" -f "$CONTAINERFILE" .
# 'set -e' ensures script exits here if podman build fails.
echo ">>> Image build successful: $IMAGE_NAME"
echo ""

# --- Setup Local Path ScripT ---
set +e # Temporarily disable errexit
echo ">>> Setting up local PATH for user..."
"$SETUP_LOCAL_PATH_SCRIPT"
local setup_exit_code=$?
set -e # Re-enable errexit
if [ $setup_exit_code -ne 0 ]; then
    echo "Warning: PATH setup script encountered an issue or was skipped by user (exit code: $setup_exit_code)."
fi
echo ">>> Local PATH setup completed. Please ensure your shell is configured to use it."
echo ""

# --- Test Step ---
echo ">>> Starting tests for image: $IMAGE_NAME..."
# Execute the test script.
# The test script is expected to handle its own error reporting and exit codes.
"$TEST_SCRIPT"
# 'set -e' and the test script (which should also use 'set -e' or exit on failure)
# ensure this script exits if any test fails.

echo ""
echo ">>> Build and test process completed successfully for $IMAGE_NAME!"

exit 0
