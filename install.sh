#!/usr/bin/env bash

# config
SCRIPT_NAME=OSXWiFiLocations
INSTALL_DIR=/usr/local/bin/
CONFIG_DIR=$HOME/.osx-wifi-locations
LAUNCH_AGENTS_DIR=$HOME/Library/LaunchAgents
LAUNCH_AGENT_CONFIG_NAME=OSXWiFiLocations.plist
LAUNCH_AGENT_CONFIG_PATH=$LAUNCH_AGENTS_DIR/$LAUNCH_AGENT_CONFIG_NAME
SERVICE_NAME=application.com.osx-wifi-locations

main() {
    # Run system compatibility check first
    check_system_compatibility

    # get sudo and maintain it
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    # clean up
    cleanup_previous_install

    # create install dir and copy script with sudo
    echo "Installing new version..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp -f "$SCRIPT_NAME" "$INSTALL_DIR"
    sudo chmod +x "$INSTALL_DIR$SCRIPT_NAME"

    # create config and agent directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LAUNCH_AGENTS_DIR"
    cp -f "$LAUNCH_AGENT_CONFIG_NAME" "$LAUNCH_AGENTS_DIR"

    # load the launch agent
    echo "Loading launch agent..."
    launchctl load -w "$LAUNCH_AGENT_CONFIG_PATH"

    verify_installation
}

# funcs
check_system_compatibility() {
    echo "Checking system compatibility..."
    
    os_version=$(sw_vers -productVersion | cut -d. -f1)
    min_version=11
    
    if [ "$os_version" -lt "$min_version" ]; then
        echo "Error: This script requires macOS $min_version (Big Sur) or later."
        echo "Current macOS version: $(sw_vers -productVersion)"
        exit 1
    fi
    
    if [ "$(uname)" != "Darwin" ]; then
        echo "Error: This script only runs on macOS."
        exit 1
    fi
    
    echo "System compatibility check passed."
}

cleanup_previous_install() {
    echo "Checking for previous installation..."
    
    if launchctl list | grep --quiet "$SERVICE_NAME"; then
        echo "Unloading existing launch agent..."
        launchctl remove "$SERVICE_NAME"
        sleep 1
    fi

    if [ -f "$INSTALL_DIR$SCRIPT_NAME" ]; then
        echo "Removing existing script..."
        sudo rm -f "$INSTALL_DIR$SCRIPT_NAME"
    fi

    if [ -f "$LAUNCH_AGENT_CONFIG_PATH" ]; then
        echo "Removing existing launch agent configuration..."
        rm -f "$LAUNCH_AGENT_CONFIG_PATH"
    fi

    if [ -d "$CONFIG_DIR" ]; then
        read -p "Existing configuration directory found. Remove it? (y/N): " remove_config
        if [[ $remove_config =~ ^[Yy]$ ]]; then
            echo "Removing existing configuration directory..."
            rm -rf "$CONFIG_DIR"
        else
            echo "Keeping existing configuration directory..."
        fi
    fi
}

verify_installation() {
    echo "Verifying installation..."
    if launchctl list | grep --quiet "$SERVICE_NAME"; then
        echo "Service successfully installed and running."
    else
        echo "Warning: Service not found. Installation might have failed."
        echo "Try manually running: launchctl load -w $LAUNCH_AGENT_CONFIG_PATH"
    fi

    echo "OS X WiFi location changer has been installed and configured successfully."
}

# run main
main