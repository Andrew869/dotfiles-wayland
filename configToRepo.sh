#!/bin/bash

config_file="pkgsConfigs.txt"
path="dot_config/"

# Leer cada línea del archivo
while IFS= read -r config || [ -n "$config" ]; do
    filePath="$HOME/.config/$config"
    if [ -e "$filePath" ]; then
        if [ -d "$filePath" ]; then
            cp -r "$filePath" "$path"
        else
            cp "$filePath" "$path"
        fi
    else
        echo "Config not found: $config"
    fi
done < "$config_file"

cp -r /usr/share/sddm/themes/sdt/ sddm-theme

# new_config=($(ls --group-directories-first $configPath))

# echo ${file_configs[*]}
# echo ${new_config[*]}