#!/bin/bash
# ============================================================
#  stopcomfy.sh — Stop ComfyUI
# ============================================================
echo "--- Stopping ComfyUI ---"
pkill -f "python main.py" 2>/dev/null
echo "--- ComfyUI stopped ---"
zenity --info --title="ComfyUI" \
  --text="✅ ComfyUI stopped — GPU freed" \
  --width=300 --timeout=2 2>/dev/null &
