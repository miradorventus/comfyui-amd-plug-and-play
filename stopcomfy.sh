#!/bin/bash
# ============================================================
#  stopcomfy.sh — Stop ComfyUI
# ============================================================

echo "--- Stopping ComfyUI ---"
pkill -f "python main.py" 2>/dev/null
pkill -f "watchdog_comfy" 2>/dev/null
echo "--- ComfyUI stopped ---"

zenity --notification \
  --text="✅ ComfyUI stopped — GPU freed" \
  --timeout=2 2>/dev/null &
