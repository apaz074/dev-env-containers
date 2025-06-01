# Use the official Debian 12 base image for Toolbox
FROM quay.io/toolbx-images/debian-toolbox:12

# Image labels
LABEL name="debian-toolbox-dev" \
      version="12-0.1" \
      summary="Debian 12 Toolbox image for modern CLI development" \
      description="Includes zsh, fzf, curl, python3, pip, pipx, pre-commit, and Neovim."

# Set environment variables for UTF-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Variables for Neovim installation
ENV NVIM_VERSION=stable
ENV NVIM_TARBALL=nvim-linux-x86_64.tar.gz
ENV NVIM_INSTALL_PATH=/opt/nvim

# Run commands as root for package installation
USER root

# Update Debian and install essential utilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        zsh \
        fzf \
        curl \
        python3 \
        python3-pip \
        # python3-venv is useful and sometimes a dependency for pipx or for the user
        python3-venv \
        git \
        # Dependencies for some tools (e.g., compilation, Neovim AppImage)
        build-essential \
        libfuse2 && \
    # Clean apt cache to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install/upgrade pip and then pipx, using --break-system-packages
# This is necessary on Debian 12+ if installing pipx globally with pip as root.
RUN python3 -m pip install --upgrade pip --break-system-packages && \
    python3 -m pip install pipx --break-system-packages
    # pip and pipx are typically installed in /usr/local/bin when run this way as root.

# Install pre-commit using pipx.
# As root, 'pipx install X' places X's binaries in ~/.local/bin (of root).
# To make it global, we use 'pipx install --global X' which puts them in /usr/local/bin (or whatever PIPX_GLOBAL_BIN_DIR defines).
# Or, if PIPX_BIN_DIR is configured, there.
# The simplest option is to ensure /usr/local/bin is in the PATH (which it usually is)
# and that pipx (installed by root) places the shims there.
# Let's assume pipx installed by root via pip places it in /usr/local/bin/pipx.
RUN /usr/local/bin/pipx install pre-commit \
    --pip-args='--no-cache-dir --force-reinstall' && \
    # 'pipx install pre-commit' as root should make pre-commit available to root.
    # For it to be available to all users, the shim must be in a global path like /usr/local/bin.
    # By default, pipx run as root installs apps for root in /root/.local/bin
    # To make it global for all users, we need the symlink to be in /usr/local/bin
    # This can be achieved if PIPX_GLOBAL_BIN_DIR is set to /usr/local/bin
    # or by using `pipx ensurepath --global` if the tool was installed with `pipx install --global <app>`
    # Alternatively, we force the global installation of pre-commit:
    rm -f /root/.local/bin/pre-commit # Remove if it was created only for root
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin /usr/local/bin/pipx install pre-commit \
    --pip-args='--no-cache-dir --force-reinstall' && \
    # Optionally, run ensurepath for the global system if necessary,
    # although by setting PIPX_BIN_DIR, the symlink should already be in /usr/local/bin.
    # /usr/local/bin/pipx ensurepath --global # May be redundant or unwanted if we only want the symlink.
    echo "pre-commit symlink should be in /usr/local/bin:" && ls -l /usr/local/bin/pre-commit


# Install Neovim (latest stable binary release)
RUN mkdir -p ${NVIM_INSTALL_PATH} && \
    curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_TARBALL}" && \
    tar -C ${NVIM_INSTALL_PATH} -xzf ${NVIM_TARBALL} && \
    # Create a symbolic link so nvim is in the standard PATH
    ln -s ${NVIM_INSTALL_PATH}/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim && \
    rm ${NVIM_TARBALL}

STOPSIGNAL SIGRTMIN+3

# Entrypoint and CMD are usually managed by Toolbox.
# We don't need to specify them here.
# User and WORKDIR are managed by Toolbox.