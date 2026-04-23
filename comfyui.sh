#!/bin/bash
# ============================================================
#  comfyui.sh — Launcher ComfyUI (on-demand)
#  Version: 1.1.2
# ============================================================

VERSION="1.1.2"
REPO_URL="https://github.com/miradorventus/comfyui-amd-plug-and-play"
RAW_URL="https://raw.githubusercontent.com/miradorventus/comfyui-amd-plug-and-play/main"

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
COMFY_DIR="$HOME/ComfyUI"
VENV_DIR="$HOME/.venvs/comfyui"
LOCK_FILE="/tmp/comfyui.lock"

# --- Manual update via CLI ---
if [ "$1" = "--update" ]; then
  echo "🔄 Updating ComfyUI Plug & Play..."
  REPO_DIR="$HOME/comfyui-amd-plug-and-play"
  if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR" && git pull && \
      cp comfyui.sh stopcomfy.sh watchdog_comfy.sh telecharger_modele.sh detect_browser.sh "$HOME/" 2>/dev/null
    chmod +x "$HOME/comfyui.sh" "$HOME/stopcomfy.sh" "$HOME/watchdog_comfy.sh" \
             "$HOME/telecharger_modele.sh" "$HOME/detect_browser.sh"
    echo "✅ Updated"
  else
    echo "⚠️ Repo not found at $REPO_DIR"
  fi
  exit 0
fi

error_popup() {
  zenity --error --title="ComfyUI — Error" --text="$1" \
    --extra-button="View log" --width=400 2>/dev/null
  [ $? -eq 1 ] && zenity --text-info --title="Logs" \
    --filename="$HOME/comfyui.log" --width=700 --height=400 2>/dev/null
}

# ============================================================
# STEP 1 — Check for updates FIRST (silent if none)
# ============================================================
LATEST=$(curl -fsSL --max-time 3 "$RAW_URL/comfyui.sh" 2>/dev/null | grep -oP '^VERSION="\K[^"]+' | head -1)

if [ -n "$LATEST" ] && [ "$LATEST" != "$VERSION" ]; then
  zenity --question \
    --title="ComfyUI — Update available 🎉" \
    --text="A new version is available!\n\nCurrent: $VERSION\nLatest:  $LATEST\n\nUpdate now?" \
    --width=400 2>/dev/null
  if [ $? -eq 0 ]; then
    REPO_DIR="$HOME/comfyui-amd-plug-and-play"
    if [ -d "$REPO_DIR/.git" ]; then
      (
        echo "20"; echo "# Pulling updates..."
        cd "$REPO_DIR" && git pull > /dev/null 2>&1
        echo "60"; echo "# Copying scripts..."
        cp comfyui.sh stopcomfy.sh watchdog_comfy.sh telecharger_modele.sh detect_browser.sh "$HOME/" 2>/dev/null
        chmod +x "$HOME/comfyui.sh" "$HOME/stopcomfy.sh" "$HOME/watchdog_comfy.sh" \
                 "$HOME/telecharger_modele.sh" "$HOME/detect_browser.sh"
        echo "100"
      ) | zenity --progress \
          --title="ComfyUI — Updating" \
          --text="Updating to $LATEST..." \
          --percentage=0 --auto-close --width=400 2>/dev/null
      
      zenity --info --title="✅ Updated" \
        --text="Updated to version $LATEST!\nRelaunching..." \
        --width=400 --timeout=2 2>/dev/null
      
      exec "$HOME/comfyui.sh"
    else
      zenity --warning --title="Manual update needed" \
        --text="Please update manually:\ncd ~/comfyui-amd-plug-and-play && git pull" \
        --width=400 2>/dev/null
    fi
  fi
fi

# ============================================================
# STEP 2 — Check if already running
# ============================================================
if pgrep -f "python main.py" > /dev/null; then
  zenity --question \
    --title="ComfyUI — Already running" \
    --text="⚠️ ComfyUI is already running.\n\nOpen a new tab or reset everything?" \
    --ok-label="New tab" --cancel-label="Reset services" \
    --width=450 2>/dev/null
  if [ $? -eq 0 ]; then
    BROWSER=$(/home/ia/detect_browser.sh | cut -d"|" -f1)
    case "$BROWSER" in
      firefox)
        PROFILE_DIR="$HOME/snap/firefox/common/.mozilla/firefox/comfyui-profile"
        firefox --no-remote --profile "$PROFILE_DIR" --new-tab http://127.0.0.1:8188 2>/dev/null &
        ;;
      microsoft-edge) microsoft-edge --new-tab http://127.0.0.1:8188 2>/dev/null & ;;
      google-chrome) google-chrome --new-tab http://127.0.0.1:8188 2>/dev/null & ;;
      *) xdg-open http://127.0.0.1:8188 2>/dev/null ;;
    esac
    exit 0
  else
    # Confirm reset (avoid misclick)
    zenity --question \
      --title="ComfyUI — Confirm reset" \
      --text="⚠️ Are you sure you want to reset?\n\nThis will stop ComfyUI and free your GPU.\nYou will need to relaunch afterwards." \
      --ok-label="Yes, reset" --cancel-label="Cancel" \
      --width=450 2>/dev/null
    if [ $? -ne 0 ]; then
      exit 0
    fi
    
    # Ask user to close browsers
    zenity --info \
      --title="ComfyUI — Reset" \
      --text="⚠️ Please close ALL ComfyUI browser tabs/windows.\n\nClick OK when done." \
      --width=500 2>/dev/null
    
    # Watchdog
    (
      echo "# Waiting for ComfyUI windows to close..."
      while pgrep -f "firefox.*comfyui-profile" > /dev/null 2>&1; do
        sleep 1
      done
      echo "# Stopping ComfyUI..."
      /home/ia/stopcomfy.sh
      echo "# Restarting..."
      sleep 1
    ) | zenity --progress \
        --title="ComfyUI — Resetting" \
        --text="Waiting for browser..." \
        --pulsate --auto-close --no-cancel --width=450 2>/dev/null
    
    rm -f "$LOCK_FILE"
    exec "$HOME/comfyui.sh"
  fi
fi

# Mark as running
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# ============================================================
# STEP 3 — Loading window with startup
# ============================================================
(
  echo "# Activating Python environment..."
  source "$VENV_DIR/bin/activate" 2>/dev/null
  sleep 1

  echo "# Starting ComfyUI..."
  cd "$COMFY_DIR"
  python main.py --listen 0.0.0.0 > "$HOME/comfyui.log" 2>&1 &
  COMFY_PID=$!
  echo $COMFY_PID > /tmp/comfyui.pid

  echo "# Waiting for GPU initialization..."
  for i in {1..60}; do
    curl -s http://127.0.0.1:8188 > /dev/null 2>&1 && break
    sleep 1
  done

  echo "# Starting VRAM watchdog..."
  bash "$HOME/watchdog_comfy.sh" > "$HOME/comfyui_watchdog.log" 2>&1 &

  echo "# Almost ready..."
  sleep 1
) | zenity --progress \
    --title="ComfyUI — Starting" \
    --text="Initializing..." \
    --pulsate --auto-close \
    --no-cancel --width=450 2>/dev/null

# ============================================================
# STEP 4 — Verify it's up
# ============================================================
if ! curl -s http://127.0.0.1:8188 > /dev/null 2>&1; then
  error_popup "❌ ComfyUI is not responding.\nCheck logs for details."
  exit 1
fi

# ============================================================
# STEP 5 — Open browser
# ============================================================
BROWSER=$(/home/ia/detect_browser.sh | cut -d'|' -f1)

case "$BROWSER" in
  firefox)
    PROFILE_DIR="$HOME/snap/firefox/common/.mozilla/firefox/comfyui-profile"
    mkdir -p "$PROFILE_DIR"
    firefox --no-remote --profile "$PROFILE_DIR" http://127.0.0.1:8188 2>/dev/null
    ;;
  microsoft-edge)
    microsoft-edge --new-tab http://127.0.0.1:8188 2>/dev/null &
    zenity --info --title="ComfyUI" \
      --text="✅ ComfyUI is ready!\n\nClick STOP to close and free your GPU." \
      --ok-label="Stop" --width=400 2>/dev/null
    ;;
  google-chrome)
    google-chrome --new-tab http://127.0.0.1:8188 2>/dev/null &
    zenity --info --title="ComfyUI" \
      --text="✅ ComfyUI is ready!\n\nClick STOP to close and free your GPU." \
      --ok-label="Stop" --width=400 2>/dev/null
    ;;
  *)
    xdg-open http://127.0.0.1:8188
    zenity --info --title="ComfyUI" \
      --text="✅ ComfyUI is ready!\n\nClick STOP to close and free your GPU." \
      --ok-label="Stop" --width=400 2>/dev/null
    ;;
esac

# Cleanup on exit
/home/ia/stopcomfy.sh
