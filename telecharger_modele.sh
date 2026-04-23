#!/bin/bash
# ============================================================
#  telecharger_modele.sh — Download ComfyUI models
#  Standard layout: ~/ComfyUI/models/
# ============================================================

MODELS_DIR="$HOME/ComfyUI/models"

if [ ! -d "$MODELS_DIR" ]; then
  zenity --error --title="ComfyUI not found" \
    --text="❌ ComfyUI is not installed.\nExpected: $MODELS_DIR" \
    --width=400 2>/dev/null
  exit 1
fi

# Ask URL via zenity
URL=$(zenity --entry \
  --title="Download a model" \
  --text="Paste the model URL:\n\n(From HuggingFace, Civitai, etc.)" \
  --width=600 2>/dev/null)

[ $? -ne 0 ] && exit 0
[ -z "$URL" ] && exit 0

# Choose folder
FOLDER=$(zenity --list \
  --title="Choose the model folder" \
  --text="Where should this model be saved?" \
  --radiolist \
  --column="" --column="Folder" --column="Description" \
  TRUE  "checkpoints"      "Main models (SD1.5, SDXL, Flux...)" \
  FALSE "loras"            "LoRA (styles, characters...)" \
  FALSE "vae"              "VAE (better colors)" \
  FALSE "controlnet"       "ControlNet (pose, edges...)" \
  FALSE "upscale_models"   "Image upscaling" \
  FALSE "embeddings"       "Textual inversions" \
  FALSE "text_encoders"    "Text encoders (Flux...)" \
  FALSE "clip_vision"      "CLIP Vision" \
  --width=600 --height=400 2>/dev/null)

[ $? -ne 0 ] && exit 0
[ -z "$FOLDER" ] && exit 0

TARGET_DIR="$MODELS_DIR/$FOLDER"
mkdir -p "$TARGET_DIR"

# Extract filename from URL
FILENAME=$(basename "$URL" | cut -d'?' -f1)

# Ask for filename
FILENAME=$(zenity --entry \
  --title="File name" \
  --text="Save as:" \
  --entry-text="$FILENAME" \
  --width=500 2>/dev/null)

[ $? -ne 0 ] && exit 0
[ -z "$FILENAME" ] && exit 0

TARGET_FILE="$TARGET_DIR/$FILENAME"

# Download with progress
echo "Downloading $URL"
echo "To: $TARGET_FILE"
echo ""

wget -c "$URL" -O "$TARGET_FILE" 2>&1 | \
  stdbuf -oL awk '/[0-9]+%/{gsub(/[^0-9]/, "", $7); print $7}' | \
  zenity --progress \
    --title="Downloading $FILENAME" \
    --text="Downloading model..." \
    --auto-close --width=500 2>/dev/null

if [ ${PIPESTATUS[0]} -eq 0 ] && [ -s "$TARGET_FILE" ]; then
  SIZE=$(du -h "$TARGET_FILE" | cut -f1)
  zenity --info --title="Download complete" \
    --text="✅ Model downloaded successfully!\n\nLocation: $TARGET_FILE\nSize: $SIZE" \
    --width=500 2>/dev/null
else
  rm -f "$TARGET_FILE"
  zenity --error --title="Download failed" \
    --text="❌ Download failed or file is empty.\nCheck the URL and try again." \
    --width=400 2>/dev/null
fi
