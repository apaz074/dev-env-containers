#!/bin/bash
# test/test_image_uv.sh

# This script verifies the correct installation and configuration of uv and uvx
# within a container created from the specified image.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# The image name to test. Can be passed as the first argument,
# otherwise defaults to 'debian-toolbox-uv:12-0.1'.
IMAGE_TO_TEST="${1:-debian-toolbox-uv:12-0.1}"
# Prefix for unique container names to avoid collisions.
CONTAINER_NAME_PREFIX="uv-test-run-$(date +%s)"

echo ">>> Starting UV Verification Script for: $IMAGE_TO_TEST ---"

# --- Helper Function to run commands in the container ---
# This function takes a command string as an argument,
# runs it inside a new ephemeral container from IMAGE_TO_TEST,
# and returns the exit code of the command.
run_in_test_container() {
    local command_to_run="$1"
    echo "--- Executing in test container: $command_to_run ---"
    # --rm: Automatically remove the container when it exits.
    # A unique name is generated using the prefix and current PID ($$).
    if podman run --rm --name "${CONTAINER_NAME_PREFIX}-$$" "$IMAGE_TO_TEST" bash -c "$command_to_run"; then
        echo "Command executed successfully."
        return 0 # Success
    else
        echo "ERROR: Command failed with exit code $?."
        return 1 # Failure
    fi
}

# --- Verification Steps ---

# Step 1: Verify uv installation and get its version
echo ""
echo "Step 1: Verifying uv installation and version..."
# 'uv' should be in /bin/ (copied in Containerfile) and thus in the default PATH.
# 'command -v uv' checks if 'uv' is found in PATH.
# 'uv --version' gets the version.
if run_in_test_container "command -v uv && uv --version"; then
    echo "uv verification successful."
else
    echo "FAILURE: uv verification failed. Is uv in PATH and executable?"
    exit 1
fi

# Step 2: Verify uvx installation and get its version (or help output)
echo ""
echo "Step 2: Verifying uvx installation and version/help..."
# 'uvx' should also be in /bin/ and thus in the default PATH.
if run_in_test_container "command -v uvx && uvx --version"; then
    echo "uvx verification successful."
else
    # If 'uvx --version' fails or isn't distinct (it might be same as uv's),
    # try 'uvx --help' as a basic check for its presence and executability.
    echo "uvx --version might have failed or is not distinct, trying uvx --help..."
    # Redirect help output to /dev/null as it can be verbose.
    if run_in_test_container "uvx --help > /dev/null 2>&1"; then
        echo "uvx --help command executed successfully (uvx is present)."
    else
        echo "FAILURE: uvx verification failed. Is uvx in PATH and executable?"
        exit 1
    fi
fi

# Step 3: Verify UV environment variables are set as defined in the Containerfile
echo ""
echo "Step 3: Verifying UV environment variables..."
# This command string will print the values of the ENV variables and then test them.
VERIFY_ENVS_COMMAND='echo "PYTHONUNBUFFERED=$PYTHONUNBUFFERED"; echo "UV_COMPILE_BYTECODE=$UV_COMPILE_BYTECODE"; echo "UV_LINK_MODE=$UV_LINK_MODE"; \
                     test "$PYTHONUNBUFFERED" = "1" && \
                     test "$UV_COMPILE_BYTECODE" = "1" && \
                     test "$UV_LINK_MODE" = "copy"'

if run_in_test_container "$VERIFY_ENVS_COMMAND"; then
    echo "UV Environment variables verification successful."
else
    echo "FAILURE: UV Environment variables not set as expected."
    exit 1
fi


echo ""
echo "--- UV Verification Successful for: $IMAGE_TO_TEST ---"
exit 0