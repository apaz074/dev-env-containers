#!/bin/bash

# Main script to configure host PATH, build images, test them, and create a Toolbox.
# Assumes all specified Containerfiles and scripts exist at their defined paths and are executable.

# Exit immediately if a command exits with a non-zero status (except where handled).
set -e

# --- Configuration ---
BASE_IMAGE_NAME="debian-toolbox-dev:12-0.1"
BASE_CONTAINERFILE="./containerfiles/Containerfile"
BASE_TEST_SCRIPT="./scripts/test_image_base.sh"

UV_IMAGE_NAME="debian-toolbox-uv:12-0.1"
UV_CONTAINERFILE="./containerfiles/Containerfile.uv"
UV_TEST_SCRIPT="./scripts/test_image_uv.sh"

SETUP_LOCAL_PATH_SCRIPT="./scripts/setup_local_path.sh"
PYTHON_TOOLBOX_NAME="python-toolbox-dev"

# --- Prerequisite Checks (Tools only) ---
echo ">>> Performing prerequisite checks for tools..."
if ! command -v podman &> /dev/null; then
    echo "Error: Podman is not installed. Please install Podman."
    exit 1
fi
if ! command -v toolbox &> /dev/null; then
    echo "Error: toolbox is not installed."
    exit 1
fi
echo ">>> Prerequisite tool checks passed."
echo ""

# --- Step 1: Setup Host User PATH (Optional - User will be prompted) ---
echo ">>> Running host user PATH setup script ($SETUP_LOCAL_PATH_SCRIPT)..."
set +e 
"$SETUP_LOCAL_PATH_SCRIPT"
local setup_exit_code=$?
set -e 
if [ $setup_exit_code -ne 0 ]; then
    echo "Warning: PATH setup script encountered an issue or was skipped by user (exit code: $setup_exit_code)."
fi
echo ">>> Host user PATH setup script finished."
echo "    If changes were made, please source your shell config or open a new terminal"
echo "    for them to take full effect before proceeding if subsequent steps depend on it."
echo ""

# --- Step 2: Build and Test Base Debian Toolbox Image ---
echo ">>> Building base image: $BASE_IMAGE_NAME using $BASE_CONTAINERFILE..."
podman build -t "$BASE_IMAGE_NAME" -f "$BASE_CONTAINERFILE" .
echo ">>> Image build successful: $BASE_IMAGE_NAME"
echo ""

echo ">>> Starting tests for base image: $BASE_IMAGE_NAME..."
"$BASE_TEST_SCRIPT" "$BASE_IMAGE_NAME" 
echo ">>> Tests for base image $BASE_IMAGE_NAME completed."
echo ""

# --- Step 3: Build and Test Debian Toolbox UV Image ---
echo ">>> Building UV image: $UV_IMAGE_NAME using $UV_CONTAINERFILE..."
echo "    (This image is based on $BASE_IMAGE_NAME)"
podman build -t "$UV_IMAGE_NAME" -f "$UV_CONTAINERFILE" .
echo ">>> Image build successful: $UV_IMAGE_NAME"
echo ""

echo ">>> Starting tests for UV image: $UV_IMAGE_NAME..."
"$UV_TEST_SCRIPT" "$UV_IMAGE_NAME" 
echo ">>> Tests for UV image $UV_IMAGE_NAME completed."
echo ""

# --- Step 4: Create Python Development Toolbox Container ---
echo ">>> Preparing Toolbox container: $PYTHON_TOOLBOX_NAME from image $UV_IMAGE_NAME..."

# Attempt to remove the toolbox if it exists. --force supresses errors if it doesn't exist.
echo "Attempting to remove existing Toolbox (if any): $PYTHON_TOOLBOX_NAME..."
if ! toolbox rm "$PYTHON_TOOLBOX_NAME" --force; then
    # Even with --force, 'toolbox rm' might return an error for reasons other than "not found"
    # (e.g., if the container is running and cannot be force-removed by the current user,
    # or other underlying podman issues). It's good to check the exit code.
    echo "Warning: 'toolbox rm --force $PYTHON_TOOLBOX_NAME' exited with an error."
    echo "         This might be okay if the toolbox didn't exist, or it could indicate an issue."
    echo "         Proceeding with creation attempt..."
fi

# Create the new toolbox container
echo "Creating new Toolbox: $PYTHON_TOOLBOX_NAME..."
if ! toolbox create --image "$UV_IMAGE_NAME" "$PYTHON_TOOLBOX_NAME"; then 
    echo "Error: Failed to create Toolbox '$PYTHON_TOOLBOX_NAME'."
    exit 1
fi

echo ""
echo ">>> Toolbox container '$PYTHON_TOOLBOX_NAME' created successfully from image '$UV_IMAGE_NAME'."
echo "    You can enter it using: toolbox enter $PYTHON_TOOLBOX_NAME"
echo ""

# --- Final Summary ---
echo ">>> All build and setup processes completed successfully!"
echo "    Host PATH setup was attempted (check messages above for status)."
echo "    Base image '$BASE_IMAGE_NAME' was built and tested."
echo "    UV image '$UV_IMAGE_NAME' was built and tested."
echo "    Toolbox container '$PYTHON_TOOLBOX_NAME' is ready."
exit 0
