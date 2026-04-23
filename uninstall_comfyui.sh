#!/bin/bash
# ============================================================
#  uninstall_comfyui.sh
#  Standard layout: ~/ComfyUI and ~/.venvs/comfyui
# ============================================================

LOG_FILE="$HOME/uninstall_comfyui.log"
STATUS_FILE=$(mktemp)

COMFY_DIR="$HOME/ComfyUI"
VENV_DIR="$HOME/.venvs/comfyui"

if ! command -v zenity &>/dev/null; then
  sudo apt install zenity -y
fi

MSG="⚠️ Uninstall ComfyUI?\n\nThis will remove:\n• $COMFY_DIR (git repo)\n• $VENV_DIR (Python environment)\n• Scripts and desktop shortcuts\n\n⚠️ Your models in ~/ComfyUI/models/ will be deleted!"

zenity --question --title="Uninstall ComfyUI" --text="$MSG" --width=450 2>/dev/null
[ $? -ne 0 ] && exit 0

KEEP_MODELS=false
zenity --question --title="Models backup" \
  --text="Do you want to save your models before uninstalling?" \
  --ok-label="Keep models" --cancel-label="Delete everything" \
  --width=400 2>/dev/null
[ $? -eq 0 ] && KEEP_MODELS=true

echo "=== Uninstall log — $(date) ===" > "$LOG_FILE"
log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"; }

uninstall() {
  log "=== Stopping ComfyUI ==="
  pkill -f "python main.py" 2>/dev/null
  pkill -f "watchdog_comfy" 2>/dev/null
  sleep 2

  if [ "$KEEP_MODELS" = true ] && [ -d "$COMFY_DIR/models" ]; then
    log "Saving models to ~/comfyui_models_backup..."
    cp -r "$COMFY_DIR/models" "$HOME/comfyui_models_backup"
    log "Models saved ✅"
  fi

  log "Removing $COMFY_DIR..."
  rm -rf "$COMFY_DIR"

  log "Removing $VENV_DIR..."
  rm -rf "$VENV_DIR"

  log "Removing scripts..."
  rm -f ~/comfyui.sh ~/stopcomfy.sh ~/watchdog_comfy.sh ~/telecharger_modele.sh

  log "Removing desktop shortcuts..."
  rm -f ~/Bureau/ComfyUI.desktop ~/Desktop/ComfyUI.desktop
  rm -f ~/Bureau/DL-Model.desktop ~/Desktop/DL-Model.desktop
  rm -f ~/Bureau/DL-Modele.desktop ~/Desktop/DL-Modele.desktop

  log "✅ Uninstall complete!"
  echo "SUCCESS" > "$STATUS_FILE"
}

uninstall &
PID=$!

tail -n 15 -f "$LOG_FILE" 2>/dev/null | zenity --text-info \
  --title="ComfyUI — Uninstalling..." \
  --width=600 --height=300 \
  --no-wrap --ok-label="Close" 2>/dev/null &
ZENITY_PID=$!

while kill -0 $PID 2>/dev/null; do sleep 1; done
kill $ZENITY_PID 2>/dev/null

STATUS=$(cat "$STATUS_FILE" 2>/dev/null)
rm -f "$STATUS_FILE"

if [ "$STATUS" = "SUCCESS" ]; then
  MSG_FINAL="✅ ComfyUI has been uninstalled."
  [ "$KEEP_MODELS" = true ] && MSG_FINAL="$MSG_FINAL\n\nYour models are saved in ~/comfyui_models_backup"
  zenity --info --title="Uninstall complete" --text="$MSG_FINAL" --width=400 2>/dev/null
else
  zenity --warning --title="Uninstall" --text="⚠️ Uninstall was interrupted." --width=350 2>/dev/null
fi

exit 0
