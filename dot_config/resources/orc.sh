#!/bin/bash

# Optical Character Recognition

# Temporary file for the screenshot
IMAGE_PATH=$(mktemp --suffix=.png)

# Function to run after freeze
AFTER_CMD=$(cat << EOF
bash -c '
  REGION=\$(slurp)
  grim -g "\$REGION" "$IMAGE_PATH"
  TEXT=\$(tesseract "$IMAGE_PATH" - -l eng+spa)
  rm "$IMAGE_PATH"
  TEXT_CLEAN=\$(echo "\$TEXT" | sed "s/^[ \\t\\n\\r]*//;s/[ \\t\\n\\r]*\$//")
  if [[ -n "\$TEXT_CLEAN" ]]; then
    echo "\$TEXT_CLEAN" | wl-copy
    notify-send "OCR Text Extracted" "\$TEXT_CLEAN"
  fi
  killall wayfreeze
'
EOF
)

# Run wayfreeze with the after-freeze command
wayfreeze --hide-cursor --after-freeze-cmd "$AFTER_CMD"

