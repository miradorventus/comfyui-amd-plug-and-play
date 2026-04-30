#!/bin/bash
# ============================================================
#  comfyui-launcher.sh — Launcher ComfyUI (on-demand)
#  Version: 1.0.0
# ============================================================

VERSION="2.0.1"
REPO_URL="https://github.com/miradorventus/comfyui-amd-plug-and-play"
RAW_URL="https://raw.githubusercontent.com/miradorventus/comfyui-amd-plug-and-play/main"

# Self-detect: launcher uses its own folder (works for default ~/.comfyui/ and custom locations)
COMFYUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMFY_DIR="$HOME/ComfyUI"
VENV_DIR="$HOME/.venvs/comfyui"
LOCK_FILE="/tmp/comfyui.lock"
URL="http://127.0.0.1:8188"

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Legacy migration: rename old comfyui.sh -> comfyui-launcher.sh
if [ -f "$COMFYUI_DIR/comfyui.sh" ] && [ ! -f "$COMFYUI_DIR/comfyui-launcher.sh" ]; then
  mv "$COMFYUI_DIR/comfyui.sh" "$COMFYUI_DIR/comfyui-launcher.sh" 2>/dev/null
fi

# Legacy migration: move old files from ~/ to COMFYUI_DIR
for old_file in stopcomfy.sh watchdog_comfy.sh detect_browser.sh ezmodl.sh; do
  if [ -f "$HOME/$old_file" ] && [ ! -f "$COMFYUI_DIR/$old_file" ]; then
    mv "$HOME/$old_file" "$COMFYUI_DIR/$old_file" 2>/dev/null
  fi
done

# ─── Manual update via CLI ──────────────────────────────────
if [ "$1" = "--update" ]; then
  echo "🔄 Updating ComfyUI Plug & Play..."
  REPO_DIR="$HOME/comfyui-amd-plug-and-play"
  if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR" && git pull && \
      cp comfyui-launcher.sh stopcomfy.sh watchdog_comfy.sh ezmodl.sh detect_browser.sh "$COMFYUI_DIR/" 2>/dev/null
    chmod +x "$COMFYUI_DIR/comfyui-launcher.sh" "$COMFYUI_DIR/stopcomfy.sh" "$COMFYUI_DIR/watchdog_comfy.sh" \
             "$COMFYUI_DIR/ezmodl.sh" "$COMFYUI_DIR/detect_browser.sh"
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
    --filename="$COMFYUI_DIR/comfyui.log" --width=700 --height=400 2>/dev/null
}

# ============================================================
# AUTO GPU CONFIG — exports HIP_VISIBLE_DEVICES on multi-GPU AMD setups
# Runs silently, only acts if 2+ AMD GPUs detected (APU + dGPU)
# ============================================================
auto_configure_gpu() {
  # Skip if already set in environment
  [ -n "$HIP_VISIBLE_DEVICES" ] && return 0
  
  # Detect AMD dGPU index (only relevant if 2+ AMD GPUs)
  local AMD_GPU_COUNT=0
  local DGPU_INDEX=-1
  local INDEX=0
  
  while IFS= read -r line; do
    if echo "$line" | grep -qiE "Navi|RX [0-9]"; then
      [ "$DGPU_INDEX" -eq -1 ] && DGPU_INDEX=$INDEX
      AMD_GPU_COUNT=$((AMD_GPU_COUNT+1))
      INDEX=$((INDEX+1))
    elif echo "$line" | grep -qiE "AMD|ATI"; then
      AMD_GPU_COUNT=$((AMD_GPU_COUNT+1))
      INDEX=$((INDEX+1))
    fi
  done < <(lspci | grep -E "VGA|3D")
  
  # Only configure if 2+ AMD GPUs (split iGPU+dGPU setup)
  [ "$AMD_GPU_COUNT" -lt 2 ] && return 0
  [ "$DGPU_INDEX" -lt 0 ] && return 0
  
  # Export for the python main.py we'll launch
  export HIP_VISIBLE_DEVICES=$DGPU_INDEX
}

# ============================================================
# STEP 1 — ALREADY RUNNING ? (info popup if yes)
# ============================================================
if [ -f "$LOCK_FILE" ]; then
  OLD_PID=$(cat "$LOCK_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    zenity --info --title="ComfyUI — Already running" \
      --text="ComfyUI is already running.\n\nIt opened in an isolated Firefox window.\nLook for the Firefox window with ComfyUI\nat 127.0.0.1:8188.\n\n💡 Tip: in that Firefox window, press Ctrl+T\nto open more tabs.\n\nTo restart fresh: close that Firefox window first." \
      --width=450 --timeout=8 2>/dev/null
    exit 0
  else
    rm -f "$LOCK_FILE"
  fi
fi

# Also check if python main.py is running (defensive: lockfile may have been deleted)
if pgrep -f "python.*main.py.*--listen" > /dev/null; then
  zenity --info --title="ComfyUI — Already running" \
    --text="ComfyUI is already running.\n\nLook for the Firefox window with ComfyUI\nat 127.0.0.1:8188." \
    --width=450 --timeout=8 2>/dev/null
  exit 0
fi

# ============================================================
# STEP 2 — INTEGRITY CHECK (silent if all OK)
# ============================================================
INT_MISSING=""
[ -d "$COMFY_DIR" ] || INT_MISSING+="\n  • ComfyUI repo ($COMFY_DIR)"
[ -d "$VENV_DIR" ] || INT_MISSING+="\n  • Python venv ($VENV_DIR)"
[ -f "$VENV_DIR/bin/python" ] || INT_MISSING+="\n  • Python in venv"
[ -f "$COMFY_DIR/main.py" ] || INT_MISSING+="\n  • ComfyUI main.py"
[ -f "$COMFYUI_DIR/stopcomfy.sh" ] || INT_MISSING+="\n  • stopcomfy.sh script"
[ -f "$COMFYUI_DIR/watchdog_comfy.sh" ] || INT_MISSING+="\n  • watchdog_comfy.sh script"
[ -f "$COMFYUI_DIR/detect_browser.sh" ] || INT_MISSING+="\n  • detect_browser.sh script"

if [ -n "$INT_MISSING" ]; then
  zenity --question --title="ComfyUI — Repair needed" \
    --text="Some components are missing or broken:$INT_MISSING\n\nRun the installer to fix only what's missing." \
    --ok-label="✅ Repair now" --cancel-label="❌ Cancel" --width=500 2>/dev/null
  if [ $? -eq 0 ]; then
    if [ -x "$HOME/comfyui-amd-plug-and-play/install_comfyui.sh" ]; then
      exec "$HOME/comfyui-amd-plug-and-play/install_comfyui.sh"
    else
      error_popup "Installer not found at\n$HOME/comfyui-amd-plug-and-play/install_comfyui.sh\n\nClone the repo first:\ngit clone $REPO_URL"
    fi
  fi
  exit 0
fi

# ============================================================
# STEP 2.5 — AUTO GPU CONFIG (silent, only if needed)
# ============================================================
auto_configure_gpu

# ============================================================
# STEP 3 — CHECK FOR UPDATES (silent if none)
# ============================================================
LATEST=$(curl -fsSL --max-time 3 "$RAW_URL/comfyui-launcher.sh" 2>/dev/null | grep -oP '^VERSION="\K[^"]+' | head -1)

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
        cp comfyui-launcher.sh stopcomfy.sh watchdog_comfy.sh ezmodl.sh detect_browser.sh "$COMFYUI_DIR/" 2>/dev/null
        chmod +x "$COMFYUI_DIR/comfyui-launcher.sh" "$COMFYUI_DIR/stopcomfy.sh" "$COMFYUI_DIR/watchdog_comfy.sh" \
                 "$COMFYUI_DIR/ezmodl.sh" "$COMFYUI_DIR/detect_browser.sh"
        echo "100"
      ) | zenity --progress --title="ComfyUI — Updating" \
          --text="Updating to $LATEST..." \
          --percentage=0 --auto-close --width=400 2>/dev/null
      
      zenity --info --title="✅ Updated" \
        --text="Updated to version $LATEST!\nRelaunching..." \
        --width=400 --timeout=2 2>/dev/null
      exec "$COMFYUI_DIR/comfyui-launcher.sh"
    else
      zenity --warning --title="Manual update needed" \
        --text="Please update manually:\ncd ~/comfyui-amd-plug-and-play && git pull" \
        --width=400 2>/dev/null
    fi
  fi
fi

# ============================================================
# STEP 4 — CREATE LOCKFILE + CLEANUP TRAP
# ============================================================
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"; "$COMFYUI_DIR/stopcomfy.sh" 2>/dev/null' EXIT

# ============================================================
# STEP 5 — START COMFYUI
# ============================================================
(
  echo "# Activating Python environment..."
  source "$VENV_DIR/bin/activate" 2>/dev/null
  sleep 1

  echo "# Starting ComfyUI..."
  cd "$COMFY_DIR"
  python main.py --listen 0.0.0.0 > "$COMFYUI_DIR/comfyui.log" 2>&1 &
  COMFY_PID=$!
  echo $COMFY_PID > /tmp/comfyui.pid

  echo "# Waiting for GPU initialization..."
  for i in {1..60}; do
    curl -s "$URL" > /dev/null 2>&1 && break
    sleep 1
  done

  echo "# Starting VRAM watchdog..."
  bash "$COMFYUI_DIR/watchdog_comfy.sh" > "$COMFYUI_DIR/watchdog.log" 2>&1 &

  echo "# Almost ready..."
  sleep 1
) | zenity --progress \
    --title="ComfyUI — Starting" \
    --text="Initializing..." \
    --pulsate --auto-close --no-cancel --width=450 2>/dev/null

# ============================================================
# STEP 6 — VERIFY IT'S UP
# ============================================================
if ! curl -s "$URL" > /dev/null 2>&1; then
  error_popup "❌ ComfyUI is not responding.\nCheck logs for details."
  exit 1
fi

# ============================================================
# STEP 7 — OPEN BROWSER (WebApp pattern, isolated profile)
# ============================================================
BROWSER=$("$COMFYUI_DIR/detect_browser.sh" | cut -d'|' -f1)

case "$BROWSER" in
  firefox)
    # WebApp Manager pattern: isolated profile in standard location
    PROFILE_DIR="$HOME/.local/share/ice/firefox/ComfyUI"
    mkdir -p "$PROFILE_DIR"
    # Use icon from install dir (persists if user deletes the git repo)
    ICON_PATH="$COMFYUI_DIR/icon.png"
    [ ! -f "$ICON_PATH" ] && ICON_PATH=""
    XAPP_FORCE_GTKWINDOW_ICON="$ICON_PATH" firefox \
      --class WebApp-ComfyUI \
      --name WebApp-ComfyUI \
      --profile "$PROFILE_DIR" \
      --no-remote \
      "$URL" 2>/dev/null
    ;;
  microsoft-edge|google-chrome|chromium-browser|chromium)
    "$BROWSER" --new-tab "$URL" 2>/dev/null &
    BROWSER_PID=$!
    wait $BROWSER_PID
    ;;
  *)
    xdg-open "$URL" 2>/dev/null
    sleep 3
    while pgrep -f "127.0.0.1:8188\|localhost:8188" > /dev/null 2>&1; do
      sleep 2
    done
    ;;
esac

# Trap EXIT does the cleanup (rm lockfile + stopcomfy.sh)
