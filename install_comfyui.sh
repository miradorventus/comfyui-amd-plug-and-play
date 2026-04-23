#!/bin/bash
# ============================================================
#  install_comfyui.sh
#  ComfyUI installer — AMD ROCm — Ubuntu 24.04
#  Standard layout:
#    ~/ComfyUI/        (official git repo)
#    ~/.venvs/comfyui/ (separated venv)
# ============================================================

LOG_FILE="$HOME/install_comfyui.log"
STATUS_FILE=$(mktemp)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMFY_DIR="$HOME/ComfyUI"
VENV_DIR="$HOME/.venvs/comfyui"

# --- Zenity ---
if ! command -v zenity &>/dev/null; then
  sudo apt install zenity -y
fi

# --- Sudo ---
if ! sudo -n true 2>/dev/null; then
  PASSWORD=$(zenity --password \
    --title="Authentication required" \
    --text="Enter your password to install ComfyUI:" \
    --width=400 2>/dev/null)
  [ $? -ne 0 ] && exit 0
  echo "$PASSWORD" | sudo -S -v 2>/dev/null || {
    zenity --error --title="Error" --text="❌ Wrong password." --width=300 2>/dev/null
    exit 1
  }
fi

MSG_WELCOME="Welcome to the ComfyUI installer\n\nThis will install:\n• ComfyUI in ~/ComfyUI (official repo — easy to update with 'git pull')\n• Python venv in ~/.venvs/comfyui (separated, cleaner)\n• PyTorch with ROCm acceleration\n\nRequirements:\n• Ubuntu 24.04\n• AMD GPU with ROCm support\n• ~25 GB free disk space\n• Python 3.12, Git\n\n⏳ Installation takes 10-20 minutes.\n\nLog: $LOG_FILE"
MSG_SUCCESS="✅ ComfyUI installed successfully!\n\nShortcuts 'ComfyUI' and 'DL Model' created on desktop.\n\nLaunch ComfyUI now?"
MSG_FAIL="❌ Installation failed.\n\nSee log: $LOG_FILE"

cat > "$LOG_FILE" << EOF
============================================
 ComfyUI — Installation log
 $(date)
 System : $(uname -a)
 Ubuntu : $(lsb_release -d 2>/dev/null | cut -f2)
============================================
EOF

zenity --info --title="ComfyUI Setup" --text="$MSG_WELCOME" --width=500 2>/dev/null
[ $? -ne 0 ] && exit 0

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

check_requirements() {
  log "=== Checking requirements ==="
  local MISSING=""
  local REASONS=""

  if ! grep -q "24.04" /etc/os-release; then
    REASONS="$REASONS\n• Ubuntu 24.04 required (detected: $(lsb_release -d | cut -f2))"
  fi

  if [ ! -e /dev/kfd ]; then
    MISSING="$MISSING rocm"
    log "AMD GPU driver missing"
  fi

  if ! command -v python3 &>/dev/null; then
    MISSING="$MISSING python3"
  fi

  if ! command -v git &>/dev/null; then
    MISSING="$MISSING git"
  fi

  if [ -n "$REASONS" ]; then
    zenity --question \
      --title="⚠️ Incompatibility detected" \
      --text="Issues detected:$REASONS\n\nInstallation may not work.\nCancel?" \
      --ok-label="Cancel" --cancel-label="Continue anyway" \
      --width=500 2>/dev/null
    [ $? -eq 0 ] && exit 0
  fi

  if [ -n "$MISSING" ]; then
    zenity --question \
      --title="Missing requirements" \
      --text="Missing components:\n$MISSING\n\nInstall them automatically via official repositories?" \
      --width=450 2>/dev/null
    [ $? -ne 0 ] && exit 0

    sudo apt update >> "$LOG_FILE" 2>&1
    for dep in $MISSING; do
      case $dep in
        python3) sudo apt install -y python3 python3-venv python3-pip >> "$LOG_FILE" 2>&1 ;;
        git) sudo apt install -y git >> "$LOG_FILE" 2>&1 ;;
        rocm)
          log "Installing ROCm..."
          wget -q "https://repo.radeon.com/amdgpu-install/6.3.3/ubuntu/noble/amdgpu-install_6.3.60303-1_all.deb" -O /tmp/amdgpu-install.deb >> "$LOG_FILE" 2>&1
          sudo apt install -y /tmp/amdgpu-install.deb >> "$LOG_FILE" 2>&1
          sudo amdgpu-install --usecase=rocm,hip --no-dkms -y >> "$LOG_FILE" 2>&1
          sudo usermod -aG render,video $USER >> "$LOG_FILE" 2>&1
          echo "REBOOT" > "$STATUS_FILE"
          ;;
      esac
    done

    if [ "$(cat "$STATUS_FILE" 2>/dev/null)" = "REBOOT" ]; then
      zenity --question --title="Reboot required" \
        --text="⚠️ ROCm installed. Reboot required before continuing.\nReboot now?" \
        --width=400 2>/dev/null
      [ $? -eq 0 ] && sudo reboot
      rm -f "$STATUS_FILE"
      exit 0
    fi
  fi
}

install_comfyui() {
  log "=== Cloning ComfyUI ==="
  if [ ! -d "$COMFY_DIR" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR" >> "$LOG_FILE" 2>&1 || {
      log "ERROR: git clone failed"
      echo "ERROR" > "$STATUS_FILE"
      return 1
    }
  else
    log "ComfyUI already exists, pulling latest..."
    cd "$COMFY_DIR" && git pull >> "$LOG_FILE" 2>&1
  fi

  log "=== Creating Python venv in $VENV_DIR ==="
  mkdir -p "$(dirname "$VENV_DIR")"
  python3 -m venv "$VENV_DIR" >> "$LOG_FILE" 2>&1 || {
    log "ERROR: venv creation failed"
    echo "ERROR" > "$STATUS_FILE"
    return 1
  }

  source "$VENV_DIR/bin/activate"

  log "=== Upgrading pip ==="
  pip install --upgrade pip >> "$LOG_FILE" 2>&1

  log "=== Installing PyTorch ROCm (large download ~6GB, please wait) ==="
  pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/rocm7.2 >> "$LOG_FILE" 2>&1 || {
    log "ERROR: PyTorch install failed"
    echo "ERROR" > "$STATUS_FILE"
    return 1
  }

  log "=== Installing ComfyUI requirements ==="
  pip install -r "$COMFY_DIR/requirements.txt" >> "$LOG_FILE" 2>&1 || {
    log "ERROR: requirements install failed"
    echo "ERROR" > "$STATUS_FILE"
    return 1
  }

  deactivate
  log "✅ ComfyUI installed"
}

install_scripts() {
  log "=== Installing launch scripts ==="
  cp "$SCRIPT_DIR/comfyui.sh" "$HOME/"
  cp "$SCRIPT_DIR/stopcomfy.sh" "$HOME/"
  cp "$SCRIPT_DIR/watchdog_comfy.sh" "$HOME/"
  cp "$SCRIPT_DIR/telecharger_modele.sh" "$HOME/"
  cp "$SCRIPT_DIR/detect_browser.sh" "$HOME/" 2>/dev/null || true
  chmod +x "$HOME/comfyui.sh" "$HOME/stopcomfy.sh" \
           "$HOME/watchdog_comfy.sh" "$HOME/telecharger_modele.sh" \
           "$HOME/detect_browser.sh"

  DESKTOP="$HOME/Desktop"
  [ ! -d "$DESKTOP" ] && DESKTOP="$HOME/Bureau"

  [ -f "$DESKTOP/ComfyUI.desktop" ] && cp "$DESKTOP/ComfyUI.desktop" "$DESKTOP/ComfyUI.desktop.bak"

  cat > "$DESKTOP/ComfyUI.desktop" << DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=ComfyUI
Comment=Launch ComfyUI
Exec=$HOME/comfyui.sh
Icon=utilities-terminal
Terminal=false
Categories=Application;
DESK
  gio set "$DESKTOP/ComfyUI.desktop" metadata::trusted true 2>/dev/null
  chmod +x "$DESKTOP/ComfyUI.desktop"

  cat > "$DESKTOP/DL-Model.desktop" << DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=DL Model
Comment=Download a ComfyUI model
Exec=$HOME/telecharger_modele.sh
Icon=emblem-downloads
Terminal=true
Categories=Application;
DESK
  gio set "$DESKTOP/DL-Model.desktop" metadata::trusted true 2>/dev/null
  chmod +x "$DESKTOP/DL-Model.desktop"

  log "Desktop shortcuts created"
}

main_install() {
  check_requirements
  install_comfyui || return 1
  install_scripts
  log "✅ Installation complete!"
  echo "SUCCESS" > "$STATUS_FILE"
}

main_install &
INSTALL_PID=$!

tail -n 15 -f "$LOG_FILE" 2>/dev/null | zenity --text-info \
  --title="ComfyUI Setup — Installing..." \
  --width=700 --height=400 \
  --no-wrap --cancel-label="Abort" --ok-label="Close" 2>/dev/null &
ZENITY_PID=$!

while kill -0 $INSTALL_PID 2>/dev/null; do
  if ! kill -0 $ZENITY_PID 2>/dev/null; then
    zenity --question --title="ComfyUI Setup" --text="Abort installation?" --width=350 2>/dev/null
    if [ $? -eq 0 ]; then
      kill $INSTALL_PID 2>/dev/null
      rm -f "$STATUS_FILE"
      exit 0
    else
      tail -n 15 -f "$LOG_FILE" 2>/dev/null | zenity --text-info \
        --title="ComfyUI Setup — Installing..." \
        --width=700 --height=400 --no-wrap \
        --cancel-label="Abort" --ok-label="Close" 2>/dev/null &
      ZENITY_PID=$!
    fi
  fi
  sleep 1
done

kill $ZENITY_PID 2>/dev/null

STATUS=$(cat "$STATUS_FILE" 2>/dev/null)
rm -f "$STATUS_FILE"

if [ "$STATUS" = "SUCCESS" ]; then
  zenity --info --title="ComfyUI Setup" --text="$MSG_SUCCESS" --width=450 2>/dev/null
  echo "Install done — launch from desktop shortcut"
else
  zenity --error --title="ComfyUI Setup" --text="$MSG_FAIL" \
    --extra-button="View log" --width=450 2>/dev/null
  [ $? -eq 1 ] && zenity --text-info --title="Log" --filename="$LOG_FILE" --width=800 --height=500 2>/dev/null
fi

exit 0
