#!/bin/bash

# File containing the list of programs
PKGS_FILE="pkgsConfigs.txt"

# Destination directory
DEST_DIR="dot_config"

# Check if the file with program names exists
if [[ ! -f "$PKGS_FILE" ]]; then
    echo "Error: The file $PKGS_FILE does not exist."
    exit 1
fi

# Create the destination directory if it does not exist
mkdir -p "$DEST_DIR"

# Read each line of the file and copy the configuration files
while IFS= read -r program || [[ -n "$program" ]]; do
    # Source and destination paths
    SRC="$HOME/.config/$program"
    DEST="$DEST_DIR/"

    # Check if the configuration folder exists
    if [[ -d "$SRC" ]]; then
        echo "Copying configuration for $program..."
        if [[ "$program" == "ranger" ]]; then
            CONFPATH="$DEST/ranger"
            # Copy all ranger files except the "plugins" folder
            mkdir -p "$DEST/ranger"
            rsync -a --exclude="plugins" "$SRC/" "$CONFPATH"
        else
            cp -r "$SRC" "$DEST"
        fi
    else
        echo "Warning: Configuration for $program not found in ~/.config/"
    fi
done < "$PKGS_FILE"

echo "Configuration backup complete. Configurations saved in $DEST_DIR/"
