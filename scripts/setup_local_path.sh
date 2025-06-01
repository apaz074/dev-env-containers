#!/bin/bash

# This script attempts to ensure that the user's local bin directory
# ($HOME/.local/bin) is added to their PATH environment variable by
# modifying the appropriate shell configuration file, based on $SHELL.

# Define the path to be added and the line for the config file.
# $HOME and $PATH are escaped to be written literally and expanded upon sourcing.
USER_LOCAL_BIN_DIR="$HOME/.local/bin"
PATH_EXPORT_LINE="export PATH=\"\$HOME/.local/bin:\$PATH\""

SHELL_CONFIG_FILE=""
DETECTED_SHELL_NAME=""

# Attempt to determine the user's default shell and its configuration file using $SHELL.
if [ -n "$SHELL" ]; then # Check if $SHELL variable is set
    DETECTED_SHELL_NAME=$(basename "$SHELL") # Get the base name of the shell executable (e.g., bash, zsh)

    case "$DETECTED_SHELL_NAME" in
        bash)
            SHELL_CONFIG_FILE="$HOME/.bashrc"
            # If .bashrc doesn't exist, .bash_profile or .profile are common fallbacks for login shells
            # which often source .bashrc for interactive settings.
            if [ ! -f "$SHELL_CONFIG_FILE" ] && [ -f "$HOME/.bash_profile" ]; then
                SHELL_CONFIG_FILE="$HOME/.bash_profile"
            elif [ ! -f "$SHELL_CONFIG_FILE" ] && [ -f "$HOME/.profile" ]; then
                SHELL_CONFIG_FILE="$HOME/.profile"
            fi
            ;;
        zsh)
            SHELL_CONFIG_FILE="$HOME/.zshrc"
            # Zsh typically uses .zshrc for interactive. .zprofile for login.
            # For PATH, .zshrc is common, but .zprofile might also be a place.
            # If .zshrc doesn't exist, consider .zprofile.
            if [ ! -f "$SHELL_CONFIG_FILE" ] && [ -f "$HOME/.zprofile" ]; then
                SHELL_CONFIG_FILE="$HOME/.zprofile"
            fi
            ;;
        sh | dash | ksh | csh | tcsh | fish) # Add other shells if needed
            # For generic 'sh' or if $SHELL points to something like dash,
            # .profile is the most standard place for PATH settings.
            # For fish, the config is different ($HOME/.config/fish/config.fish) and syntax too.
            # This script primarily targets bash/zsh/.profile compatible.
            if [ -f "$HOME/.profile" ]; then
                SHELL_CONFIG_FILE="$HOME/.profile"
                DETECTED_SHELL_NAME="$DETECTED_SHELL_NAME (using .profile)"
            else
                DETECTED_SHELL_NAME="$DETECTED_SHELL_NAME (no common .profile found)"
            fi
            ;;
        *)
            echo "Warning: Detected shell '$DETECTED_SHELL_NAME' from \$SHELL ($SHELL) is not explicitly handled for PATH modification."
            if [ -f "$HOME/.profile" ]; then # Fallback to .profile if it exists
                SHELL_CONFIG_FILE="$HOME/.profile"
                DETECTED_SHELL_NAME="$DETECTED_SHELL_NAME (falling back to .profile)"
            fi
            ;;
    esac
else
    echo "Warning: \$SHELL environment variable is not set."
fi

echo "--- User PATH Configuration Check ---"

# Check if a shell configuration file was successfully identified.
if [ -z "$SHELL_CONFIG_FILE" ]; then
    echo "Error: Could not determine a suitable shell configuration file to modify."
    echo "       Please manually ensure '$USER_LOCAL_BIN_DIR' is in your PATH."
    exit 1 # Exit if no config file is found, as we can't proceed.
fi

echo "Based on \$SHELL ($SHELL), detected shell seems to be: $DETECTED_SHELL_NAME"
echo "Will check/update configuration file: $SHELL_CONFIG_FILE"

# Check if the shell configuration file exists.
if [ ! -f "$SHELL_CONFIG_FILE" ]; then
    echo "Warning: Your determined shell configuration file ($SHELL_CONFIG_FILE) does not exist."
    read -r -p "Do you want to create it and add the PATH configuration? (y/N): " create_response
    if [[ "$create_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Creating $SHELL_CONFIG_FILE..."
        # A very basic creation; specific shells might need more.
        # For .profile, .bashrc, .zshrc, just creating it empty is usually fine before appending.
        touch "$SHELL_CONFIG_FILE" 
        # If it's a known shell, a shebang might be nice, but not strictly necessary for sourcing.
        # if [ "$DETECTED_SHELL_NAME" = "bash" ]; then echo '#!/bin/bash' > "$SHELL_CONFIG_FILE"; fi
    else
        echo "Skipping PATH configuration as file does not exist and creation was declined."
        exit 1
    fi
fi

# Check if the PATH export line already exists in the configuration file.
if grep -Fxq -- "$PATH_EXPORT_LINE" "$SHELL_CONFIG_FILE"; then
    echo "'$USER_LOCAL_BIN_DIR' appears to be already configured in $SHELL_CONFIG_FILE."
else
    echo "The directory '$USER_LOCAL_BIN_DIR' is recommended for user-installed executables."
    echo "It does not appear to be explicitly added to your PATH via the line:"
    echo "  $PATH_EXPORT_LINE"
    echo "in your shell configuration file: $SHELL_CONFIG_FILE."
    
    read -r -p "Would you like to append this line to '$SHELL_CONFIG_FILE'? (y/N): " append_response
    if [[ "$append_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "" >> "$SHELL_CONFIG_FILE" 
        echo "# Added by script '$0' on $(date) to include user's local bin in PATH" >> "$SHELL_CONFIG_FILE"
        echo "$PATH_EXPORT_LINE" >> "$SHELL_CONFIG_FILE"
        echo ""
        echo "Successfully appended the PATH configuration to $SHELL_CONFIG_FILE."
        echo "To apply the changes, please either:"
        echo "  1. Source your shell configuration file (e.g., 'source $SHELL_CONFIG_FILE'), or"
        echo "  2. Open a new terminal session."
    else
        echo "Skipped automatic PATH configuration for $SHELL_CONFIG_FILE."
        echo "If you encounter 'command not found' errors for user-installed tools,"
        echo "please manually add '$USER_LOCAL_BIN_DIR' to your PATH."
    fi
fi

echo "--- PATH Configuration Check Finished ---"
exit 0