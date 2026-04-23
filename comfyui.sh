#!/bin/bash
# ============================================================
#  comfyui.sh — Launcher ComfyUI
#  Standard layout: ~/ComfyUI and ~/.venvs/comfyui
# ============================================================

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

COMFY_DIR="$HOME/ComfyUI"
VENV_DIR="$HOME/.venvs/comfyui"

error_popup() {
  zenity --error --title="ComfyUI — Error" --text="$1" \
    --extra-button="View log" --width=400 2>/dev/null
  [ $? -eq 1 ] && zenity --text-info --title="Logs" \
    --filename="$HOME/comfyui.log" --width=700 --height=400 2>/dev/null
}

if pgrep -f "python main.py" > /dev/null; then
  echo "ComfyUI is already running!"
  xdg-open http://localhost:8188
  exit 0
fi

source "$VENV_DIR/bin/activate"
cd "$COMFY_DIR"
python main.py --listen 0.0.0.0 > "$HOME/comfyui.log" 2>&1 &
COMFY_PID=$!

sleep 5

if ! kill -0 $COMFY_PID 2>/dev/null; then
  error_popup "❌ ComfyUI crashed at startup.\nCheck logs for details."
  exit 1
fi

"$HOME/watchdog_comfy.sh" > "$HOME/comfyui_watchdog.log" 2>&1 &

BROWSER=$(/home/ia/detect_browser.sh | cut -d'|' -f1)
echo "Browser detected: $BROWSER"

case "$BROWSER" in
  firefox)
    FIREFOX_PROFILE="$HOME/snap/firefox/common/.mozilla/firefox/comfyui-profile"
    mkdir -p "$FIREFOX_PROFILE"
    firefox --no-remote --profile "$FIREFOX_PROFILE" http://localhost:8188 2>/dev/null
    ;;
  microsoft-edge)
    microsoft-edge --profile-directory="ComfyUI" http://localhost:8188 2>/dev/null
    ;;
  google-chrome)
    google-chrome --profile-directory="ComfyUI" http://localhost:8188 2>/dev/null
    ;;
  *)
    xdg-open http://localhost:8188
    sleep infinity
    ;;
esac

echo "Browser closed, stopping ComfyUI..."
"$HOME/stopcomfy.sh"
