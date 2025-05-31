# dev-env-containers

This repository contains container definitions for creating development environments using Podman and Toolbox.

## Base Development Image (Debian 12)

A `Containerfile` has been defined to build a base development image based on Debian 12. This image includes essential tools for modern CLI development such as `zsh`, `fzf`, `curl`, `python3`, `pip`, `pipx`, `pre-commit`, `Neovim`, and `git`.

## Building and Testing the Image

To build the base development image, use the `build.sh` script. This script will perform the following actions:
1.  Check if Podman and Toolbox are installed.
2.  Build the image with the name `debian-toolbox-dev:12-0.1`.
3.  Execute the `setup_local_path.sh` script to configure the user's `PATH` environment variable.
4.  Execute the `test_image_base.sh` script to verify the installation of tools within the image.

Make sure you have Podman and Toolbox installed on your system. You can find more information about installing Podman here: [https://podman.io/docs/installation](https://podman.io/docs/installation) and Toolbox here: [https://containertoolbx.org/](https://containertoolbx.org/).

Before running the scripts, ensure they have execute permissions:

```bash
chmod +x build.sh test_image_base.sh setup_local_path.sh
```

Run the following command in the repository root to build and test the image:

```bash
./build.sh
```

Once built and tested, you can use the `debian-toolbox-dev:12-0.1` image as a base to create your development environments with Toolbox.

## Local PATH Setup (`setup_local_path.sh`)

The `setup_local_path.sh` script is designed to add the `$HOME/.local/bin` directory to your shell's `PATH` environment variable. This is crucial for user-installed tools (e.g., via `pipx`) to be directly accessible from the command line, both on your host system and within Toolbox containers.

The script will attempt to detect your shell (bash, zsh, etc.) and modify the corresponding configuration file (e.g., `.bashrc`, `.zshrc`, `.profile`). If the file does not exist, it will ask if you want to create it.

## Image Verification (`test_image_base.sh`)

The `test_image_base.sh` script is responsible for verifying that essential tools are correctly installed and configured within the `debian-toolbox-dev:12-0.1` image. It performs tests by executing commands inside ephemeral containers created from the image.

Additionally, it offers a guided manual interactive test to verify `pipx` functionality within a Toolbox environment, including user-level package installation and uninstallation. This test is useful for confirming that `PATH` configuration and user tools work as expected inside a Toolbox.

## Usage with Toolbox

After building the image, you can create a Toolbox environment using the following command:

```bash
toolbox create --image debian-toolbox-dev:12-0.1 my-dev-toolbox
```

Then, you can enter your development environment:

```bash
toolbox enter my-dev-toolbox
```

Inside the Toolbox, globally installed tools in the image (like `pre-commit` and `Neovim`) will be available in your `PATH`. Tools you install at the user level with `pipx` (e.g., `pipx install black`) will be installed to `$HOME/.local/bin` (which maps to your host's `$HOME/.local/bin` directory) and will be accessible thanks to the `PATH` configuration performed by `setup_local_path.sh`.
