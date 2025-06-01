#!/bin/bash

# Exit immediately if a command fails (except where explicitly handled).
set -e

IMAGE_NAME="debian-toolbox-dev:12-0.1"
CONTAINER_NAME_PREFIX="test-run-$(date +%s)" # For unique ephemeral container names

echo ">>> Testing image: $IMAGE_NAME"
echo "NOTE: Focusing on tests for tools installed directly in the image layers."
echo "      Full Toolbox environment testing (e.g., user pipx installs inside a running toolbox)"
echo "      is pending resolution of the toolbox container startup issue."
echo ""


# Executes a command inside a new, ephemeral container from the specified image.
# This is used to test tools as they are installed in the image layers.
run_in_container() {
    # $1: Command to execute inside the container
    echo "--- Executing in a new container from '$IMAGE_NAME': $1 ---"
    podman run --rm --name "${CONTAINER_NAME_PREFIX}-cmd-$$" "$IMAGE_NAME" bash -c "$1"
}

# Guides the user through a manual interactive test inside a Toolbox.
# This function does not automate the checks inside the toolbox; it provides instructions.
run_manual_toolbox_test() {
    local toolbox_test_name="manual-interactive-tb" # A descriptive name
    
    echo ""
    echo "---------------------------------------------------------------------"
    echo "--- Starting Manual Interactive Toolbox Test ---"
    echo "This function will:"
    echo "  1. Attempt to create a Toolbox named '$toolbox_test_name'."
    echo "  2. Instruct you on commands to run once you are inside."
    echo "  3. Attempt to enter the Toolbox using 'toolbox enter $toolbox_test_name'."
    echo "     (The script will pause here until you type 'exit' inside the Toolbox)."
    echo "  4. After you exit, the script will attempt to remove the Toolbox."
    echo ""
    echo "IMPORTANT: This test assumes the underlying issue of Toolbox containers"
    echo "           not reaching a 'running' state with '$IMAGE_NAME' has been resolved."
    echo "           If 'toolbox create' or 'toolbox enter' fails, the image issue persists."
    echo "---------------------------------------------------------------------"
    echo ""
    
    echo "Step 1: Attempting to create a Toolbox named '$toolbox_test_name'..."
    set +e # Temporarily disable errexit for 'toolbox create'
    toolbox create --image "$IMAGE_NAME" "$toolbox_test_name"
    local create_exit_code=$?
    set -e # Re-enable errexit

    if [ $create_exit_code -ne 0 ]; then
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "ERROR: 'toolbox create $toolbox_test_name' failed (exit code: $create_exit_code)."
        echo "This likely means the image '$IMAGE_NAME' still has issues preventing"
        echo "Toolbox containers from starting correctly. Please resolve this first."
        echo "Skipping interactive test."
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        # Attempt to remove if it was partially created
        set +e
        toolbox rm -f "$toolbox_test_name" > /dev/null 2>&1
        set -e
        return 1 
    fi

    echo ""
    echo "Toolbox '$toolbox_test_name' created successfully."
    echo ""
    echo "Step 2: Instructions for when you are INSIDE the Toolbox '$toolbox_test_name':"
    echo "          Please execute the following commands:"
    echo "          1. pipx install cowsay"
    echo "          2. cowsay -t 'Hello from interactive test!'"
    echo "          3. ls \$HOME/.local/bin/cowsay  (to see if cowsay is there)"
    echo "          4. pipx uninstall cowsay"
    echo "          5. exit                 (to leave the Toolbox and allow this script to continue)"
    echo ""
    echo "Step 3: Now, the script will attempt to enter the Toolbox."
    echo "          The script will PAUSE until you type 'exit' inside the Toolbox shell."
    echo "Press [Enter] to continue and enter the toolbox..."
    read -r # Pause for user acknowledgment

    # This command will hand control over to the new shell.
    # The script will only continue after the user types 'exit' in the toolbox.
    toolbox enter "$toolbox_test_name" 
    local enter_exit_code=$? # This will be the exit code of the toolbox shell

    if [ $enter_exit_code -ne 0 ]; then
        echo "Warning: 'toolbox enter' or the shell within the toolbox exited with a non-zero status ($enter_exit_code)."
    else
        echo "Exited from Toolbox '$toolbox_test_name'."
    fi

    echo ""
    echo "Step 4: Attempting to remove the Toolbox '$toolbox_test_name'..."
    set +e # Temporarily disable errexit for 'toolbox rm'
    toolbox rm -f "$toolbox_test_name"
    local rm_exit_code=$?
    set -e

    if [ $rm_exit_code -eq 0 ]; then
        echo "Toolbox '$toolbox_test_name' removed successfully."
    else
        echo "Warning: Could not remove Toolbox '$toolbox_test_name' (exit code: $rm_exit_code)."
        echo "Manual removal might be needed: toolbox rm -f $toolbox_test_name"
    fi
    echo "--- Manual Interactive Toolbox Test Finished ---"
    echo "---------------------------------------------------------------------"
    return 0 # Or return $enter_exit_code if that's more meaningful
}


# --- Image Layer Tool Verification (using run_in_container) ---
echo "--- Verifying Zsh ---"
run_in_container "zsh --version"

echo "--- Verifying fzf ---"
run_in_container "fzf --version"

echo "--- Verifying Python3 ---"
run_in_container "python3 --version"

echo "--- Verifying pip ---"
run_in_container "python3 -m pip --version"

echo "--- Verifying pipx ---"
run_in_container "pipx --version"

echo "--- Verifying pre-commit ---"
run_in_container "pre-commit --version"

echo "--- Verifying Neovim ---"
run_in_container "nvim --version | head -n 1"

echo "--- Verifying git ---"
run_in_container "git --version"

echo "--- Verifying UTF-8 settings ---"
run_in_container 'echo "LANG=$LANG, LC_ALL=$LC_ALL" && test "$LANG" = "C.UTF-8" && test "$LC_ALL" = "C.UTF-8"'

# --- Pending Toolbox Specific Tests ---
# TODO: Add automated test for user-level 'pipx install cowsay' within a running Toolbox environment.
# This requires the Toolbox container to start successfully (reach 'running' state).

# --- Offer to run Manual Interactive Test ---
echo ""
echo "---------------------------------------------------------------------"
read -r -p "Do you want to perform a guided manual test for user pipx install in Toolbox? (y/N): " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    run_manual_toolbox_test
else
    echo "Skipping manual interactive Toolbox test."
fi
echo "---------------------------------------------------------------------"


# --- Final Informational Message ---
echo ""
echo "--- Image Configuration Summary for: $IMAGE_NAME ---"
echo "Globally installed tools (e.g., pipx, pre-commit, nvim) are located in /usr/local/bin."
echo "These tools should be directly available in your PATH when inside the container/toolbox."
echo ""
echo "For tools installed by you (the user) with 'pipx install <app>' inside the Toolbox:"
echo "  - They will typically be installed to \$HOME/.local/bin (which is your actual host's \$HOME/.local/bin)."
echo "  - This directory (\$HOME/.local/bin) is automatically added to your PATH by the"
echo "    script /etc/profile.d/zzz_local_bin_path.sh when you enter the Toolbox."
echo "    (This PATH modification functionality can only be fully tested once the toolbox container runs correctly)."
echo "----------------------------------------------------"
echo ""
echo ">>> Basic image tool tests passed for image: $IMAGE_NAME"
echo "Reminder: Resolve the issue causing Toolbox containers from this image to not reach 'running' state"
echo "to enable full Toolbox environment testing (including user pipx installs)."