#!/bin/bash
# ============================================================
#  ezmodl.sh — EZMoDL: Download ComfyUI models
#  All standard model folders supported
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

# Choose folder — ALL standard ComfyUI model folders
FOLDER=$(zenity --list \
  --title="Choose the model folder" \
  --text="Where should this model be saved?" \
  --radiolist \
  --column="" --column="Folder" --column="Description" \
  TRUE  "checkpoints"           "Main models (SD1.5, SDXL, Flux...)" \
  FALSE "loras"                 "LoRA (styles, characters...)" \
  FALSE "vae"                   "VAE (better colors)" \
  FALSE "controlnet"            "ControlNet (pose, edges...)" \
  FALSE "upscale_models"        "Image upscaling (ESRGAN...)" \
  FALSE "embeddings"            "Textual inversions" \
  FALSE "text_encoders"         "Text encoders (Flux...)" \
  FALSE "clip"                  "CLIP models" \
  FALSE "clip_vision"           "CLIP Vision" \
  FALSE "diffusion_models"      "Diffusion models (Flux...)" \
  FALSE "diffusers"             "Diffusers format" \
  FALSE "unet"                  "UNet models" \
  FALSE "audio_encoders"        "Audio encoders" \
  FALSE "frame_interpolation"   "Frame interpolation (video)" \
  FALSE "gligen"                "GLIGEN" \
  FALSE "hypernetworks"         "Hypernetworks" \
  FALSE "latent_upscale_models" "Latent upscale" \
  FALSE "model_patches"         "Model patches" \
  FALSE "photomaker"            "PhotoMaker" \
  FALSE "style_models"          "Style models" \
  FALSE "configs"               "Configuration files" \
  FALSE "vae_approx"            "VAE approx" \
  --width=700 --height=600 2>/dev/null)

[ $? -ne 0 ] && exit 0
[ -z "$FOLDER" ] && exit 0

TARGET_DIR="$MODELS_DIR/$FOLDER"
mkdir -p "$TARGET_DIR"

# Extract filename from URL (keep original name, no renaming)
FILENAME=$(basename "$URL" | cut -d'?' -f1)

# Handle HuggingFace resolve/main URLs
if [[ "$URL" == *"/resolve/"* ]]; then
  FILENAME=$(basename "$URL" | cut -d'?' -f1)
fi

TARGET_FILE="$TARGET_DIR/$FILENAME"

# Confirm before download
zenity --question \
  --title="Confirm download" \
  --text="📥 Download this model?\n\nFile: $FILENAME\nFolder: $FOLDER\nURL: $URL" \
  --width=600 2>/dev/null
[ $? -ne 0 ] && exit 0

# Download with progress (run in background, show zenity progress)
TEMP_LOG=$(mktemp)
(wget -c "$URL" -O "$TARGET_FILE" 2>&1 | tee "$TEMP_LOG") &
WGET_PID=$!

# Zenity progress window with pulsate (no terminal visible)
(
while kill -0 $WGET_PID 2>/dev/null; do
  # Extract percentage from wget output
  PCT=$(tail -n 1 "$TEMP_LOG" 2>/dev/null | grep -oP '\d+%' | tail -n 1 | tr -d '%')
  [ -n "$PCT" ] && echo "$PCT"
  # Extract speed info
  SPEED=$(tail -n 1 "$TEMP_LOG" 2>/dev/null | grep -oP '[\d.]+[KMG]?B/s' | tail -n 1)
  [ -n "$SPEED" ] && echo "# Downloading $FILENAME — $SPEED"
  sleep 1
done
echo "100"
) | zenity --progress \
    --title="Downloading $FILENAME" \
    --text="Starting download..." \
    --percentage=0 \
    --auto-close --width=600 2>/dev/null

wait $WGET_PID
WGET_STATUS=$?
rm -f "$TEMP_LOG"

if [ $WGET_STATUS -eq 0 ] && [ -s "$TARGET_FILE" ]; then
  SIZE=$(du -h "$TARGET_FILE" | cut -f1)
  zenity --info --title="Download complete" \
    --text="✅ Model downloaded successfully!\n\nFile: $FILENAME\nFolder: $FOLDER\nSize: $SIZE" \
    --width=500 2>/dev/null
else
  rm -f "$TARGET_FILE"
  zenity --error --title="Download failed" \
    --text="❌ Download failed or file is empty.\nCheck the URL and try again." \
    --width=400 2>/dev/null
fi
