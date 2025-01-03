#!/bin/bash

# Ruta del archivo de imagen
IMAGE_PATH="$1"

# Verificar si el archivo existe
if [[ ! -f "$IMAGE_PATH" ]]; then
  echo "El archivo no existe."
  exit 1
fi

# Verificar el tipo MIME de la imagen
MIME_TYPE=$(file --mime-type -b "$IMAGE_PATH")

# Si la imagen no es PNG, convertirla a PNG temporalmente
if [[ "$MIME_TYPE" != "image/png" ]]; then
  TEMP_FILE=$(mktemp /tmp/image.XXXXXX.png)
  echo "Convirtiendo la imagen a PNG..."
  magick "$IMAGE_PATH" "$TEMP_FILE"  # Usar ImageMagick
  IMAGE_PATH="$TEMP_FILE"  # Usar la imagen convertida
fi

# Copiar la imagen al portapapeles
wl-copy < "$IMAGE_PATH"

# Si se usó un archivo temporal, eliminarlo después de copiar
if [[ "$MIME_TYPE" != "image/png" ]]; then
  rm "$IMAGE_PATH"
fi

echo "Imagen copiada al portapapeles."
