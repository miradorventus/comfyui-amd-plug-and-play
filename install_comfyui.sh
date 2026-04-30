#!/bin/bash
# ============================================================
#  install_comfyui.sh
#  ComfyUI installer — AMD ROCm — Ubuntu 24.04 / Linux Mint 22+
#  Version: 1.0.0
#  Standard layout:
#    ~/ComfyUI/        (official git repo)
#    ~/.venvs/comfyui/ (separated venv)
#    ~/.comfyui/       (our scripts + log)
# ============================================================

VERSION="2.0.1"
REPO_URL="https://github.com/miradorventus/comfyui-amd-plug-and-play"
DEFAULT_COMFYUI_DIR="$HOME/.comfyui"
COMFYUI_DIR="$DEFAULT_COMFYUI_DIR"
CUSTOM_PARENT=""
COMFY_DIR="$HOME/ComfyUI"
VENV_DIR="$HOME/.venvs/comfyui"

# Test flag: --simulate-rocm forces ROCm to MISSING list (for dev testing)
SIMULATE_ROCM=0
for arg in "$@"; do
  case "$arg" in
    --simulate-rocm) SIMULATE_ROCM=1 ;;
  esac
done

# Ensure install dir exists
mkdir -p "$COMFYUI_DIR"

# Legacy migration v1.1.x -> v1.0.0: move scripts from ~/ to ~/.comfyui/
for old_file in comfyui.sh stopcomfy.sh watchdog_comfy.sh detect_browser.sh install_comfyui.log; do
  if [ -f "$HOME/$old_file" ] && [ ! -f "$COMFYUI_DIR/$old_file" ]; then
    mv "$HOME/$old_file" "$COMFYUI_DIR/$old_file" 2>/dev/null
  fi
done
# Legacy migration v1.0.0: rename old comfyui.sh -> comfyui-launcher.sh
if [ -f "$COMFYUI_DIR/comfyui.sh" ] && [ ! -f "$COMFYUI_DIR/comfyui-launcher.sh" ]; then
  mv "$COMFYUI_DIR/comfyui.sh" "$COMFYUI_DIR/comfyui-launcher.sh" 2>/dev/null
fi
# Legacy rename: telecharger_modele.sh -> ezmodl.sh
if [ -f "$HOME/telecharger_modele.sh" ] && [ ! -f "$COMFYUI_DIR/ezmodl.sh" ]; then
  mv "$HOME/telecharger_modele.sh" "$COMFYUI_DIR/ezmodl.sh" 2>/dev/null
fi

LOG_FILE="$COMFYUI_DIR/install_comfyui.log"
STATUS_FILE=$(mktemp)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================
# Init zenity + sudo
# ============================================================

if ! command -v zenity &>/dev/null; then
  sudo apt install zenity -y
fi

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

# Init log
cat > "$LOG_FILE" << EOF
============================================
 ComfyUI — Installation log
 Version: $VERSION
 Date: $(date)
 System: $(uname -a)
 Distro: $(lsb_release -d 2>/dev/null | cut -f2)
============================================
EOF

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

MSG_FAIL="❌ Installation failed.\n\nSee log: $LOG_FILE"

# ============================================================
# UX helpers — TIPS rotation during install
# ============================================================

# 20 tips rotated during install — feel free to customize
TIPS=(
  "💡 Drag-and-drop any ComfyUI-generated image back into the canvas to recover its workflow."
  "💡 Right-click any node to access advanced settings or save it as a preset."
  "💡 ComfyUI workflows are saved as PNG files — settings are embedded in the image itself."
  "💡 Press Ctrl+B to bypass a node temporarily without deleting it."
  "💡 Models in ~/ComfyUI/models/checkpoints/ appear automatically in the Load Checkpoint node."
  "💡 Use the 'Save (API Format)' button (Dev Mode) to export workflows for Open WebUI integration."
  "💡 Hold Shift while dragging connections to create branches from a single output."
  "💡 Double-click the canvas to search for nodes by name — faster than browsing the menu."
  "🎨 With ComfyUI you can run text-to-image, image-to-image, ControlNet, upscalers, and even video."
  "🎨 SDXL, Flux, SD 1.5, SD 3.5, AnimateDiff... thousands of models await on civitai.com and HuggingFace."
  "🎨 AMD GPUs run Stable Diffusion just as fast as NVIDIA equivalents — you are in good hands."
  "🎨 Your RX 7000/9000 series GPU can handle Flux, SDXL with LoRAs, and complex ControlNet pipelines."
  "📚 First time? Try the Image to Image workflow template — easiest way to start."
  "📚 Visit civitai.com — thousands of community-made models, LoRAs, and workflows ready to use."
  "📚 Reddit r/StableDiffusion is a goldmine of tips, workflows, and inspiration."
  "⚙️ AMD GPUs use ROCm — open-source equivalent of NVIDIA CUDA. Same speed, more freedom."
  "⚙️ ComfyUI streams images progressively — you will see them appear pixel-by-pixel during generation."
  "⚙️ Models load into VRAM only when needed, so multiple workflows can coexist seamlessly."
  "🌟 If this installer made your day, a star on GitHub is appreciated."
  "🌟 Found a bug or want a feature? Issues and PRs welcome on the GitHub repo."
)

# Write TIPS to temp file so subshells (in pipes) can read them
TIPS_FILE=$(mktemp /tmp/comfyui_tips.XXXXXX)
printf '%s\n' "${TIPS[@]}" > "$TIPS_FILE"
trap 'rm -f "$TIPS_FILE" "$STATUS_FILE"' EXIT

# Detect current install phase from log content
detect_current_step() {
  local log_file="$1"
  local last_lines=$(tail -n 50 "$log_file" 2>/dev/null)

  if echo "$last_lines" | grep -q "Cloning into 'ComfyUI'"; then
    echo "📦 Cloning ComfyUI repository (~3 GB)..."
  elif echo "$last_lines" | grep -qE "Creating venv|python3 -m venv"; then
    echo "🐍 Creating Python virtual environment..."
  elif echo "$last_lines" | grep -qE "Downloading torch|torch-.*\.whl"; then
    echo "⚙️ Downloading PyTorch with ROCm support (~4 GB, the big one)..."
  elif echo "$last_lines" | grep -qE "Downloading.*\.whl"; then
    echo "📥 Downloading Python packages..."
  elif echo "$last_lines" | grep -qE "Installing collected packages"; then
    echo "🔧 Installing Python packages..."
  elif echo "$last_lines" | grep -qE "Successfully installed|installed successfully"; then
    echo "✅ Almost done — finalizing setup..."
  elif echo "$last_lines" | grep -qE "Installing ROCm|amdgpu-install"; then
    echo "🔥 Installing ROCm 7.2.2 from AMD official repos (~10 GB)..."
  elif echo "$last_lines" | grep -qE "apt install|apt-get install"; then
    echo "📦 Installing system dependencies..."
  else
    echo "⚙️ Working on it..."
  fi
}

# ============================================================
# Pre-check — sets MISSING and REASONS as globals
# ============================================================

# Globals populated by pre_check
MISSING=""
REASONS=""

pre_check() {
  log "=== Pre-check ==="

  # Accept Ubuntu 24.04 OR any Ubuntu-based distro (Linux Mint 22+, Pop!_OS, etc.)
  if ! grep -qE '^ID=(ubuntu|linuxmint)' /etc/os-release && ! grep -qE '^ID_LIKE=.*ubuntu' /etc/os-release; then
    REASONS="$REASONS\n• Ubuntu 24.04 or Ubuntu-based distro recommended (detected: $(lsb_release -d 2>/dev/null | cut -f2))"
  fi

  if [ ! -e /dev/kfd ] || [ "$SIMULATE_ROCM" = "1" ]; then
    MISSING="$MISSING rocm"
    [ "$SIMULATE_ROCM" = "1" ] && log "[TEST] --simulate-rocm flag active — forcing ROCm in MISSING" || log "AMD GPU driver missing"
  fi

  if ! command -v python3 &>/dev/null; then
    MISSING="$MISSING python3"
  fi
  # python3-venv: required for ensurepip (NOT included by default on Mint/Debian)
  if ! python3 -c "import ensurepip" &>/dev/null; then
    MISSING="$MISSING python3-venv"
  fi

  if ! command -v git &>/dev/null; then
    MISSING="$MISSING git"
  fi

  log "Pre-check done. MISSING='$MISSING' REASONS='$REASONS'"
}

# ============================================================
# Install functions
# ============================================================

install_dependencies() {
  if [ -z "$MISSING" ]; then
    log "No dependencies missing — skipping"
    return 0
  fi

  log "=== Installing missing components: $MISSING ==="
  sudo apt update >> "$LOG_FILE" 2>&1

  for dep in $MISSING; do
    case $dep in
      python3)      sudo apt install -y python3 python3-venv python3-pip python3.12-venv >> "$LOG_FILE" 2>&1 ;;
      python3-venv) sudo apt install -y python3-venv python3.12-venv >> "$LOG_FILE" 2>&1 ;;
      git)          sudo apt install -y git >> "$LOG_FILE" 2>&1 ;;
      rocm)
        log "Installing ROCm 7.2.2..."
        sudo mkdir -p --mode=0755 /etc/apt/keyrings
        wget -qO- https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
        # Repos officiels ROCm 7.2.2 (selon doc AMD)
        sudo tee /etc/apt/sources.list.d/rocm.list > /dev/null << 'ROCMREPO_EOF'
deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.2.2 noble main
deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/graphics/7.2.1/ubuntu noble main
ROCMREPO_EOF
        # Pin priority pour préférer ces repos officiels
        sudo tee /etc/apt/preferences.d/rocm-pin-600 > /dev/null << 'ROCMPIN_EOF'
Package: *
Pin: release o=repo.radeon.com
Pin-Priority: 600
ROCMPIN_EOF
        wget -q "https://repo.radeon.com/amdgpu-install/7.2.2/ubuntu/noble/amdgpu-install_7.2.2.70202-1_all.deb" \
          -O /tmp/amdgpu-install.deb >> "$LOG_FILE" 2>&1
        sudo apt install -y /tmp/amdgpu-install.deb >> "$LOG_FILE" 2>&1
        # Fix AMD repo bug: amdgpu-install écrit graphics/7.2.2 qui n'existe pas → corriger en 7.2.1
        sudo sed -i 's|graphics/7.2.2|graphics/7.2.1|g' /etc/apt/sources.list.d/rocm.list 2>/dev/null
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo amdgpu-install --usecase=rocm,hip --no-dkms -y >> "$LOG_FILE" 2>&1
        sudo usermod -aG render,video $USER >> "$LOG_FILE" 2>&1
        touch "$COMFYUI_DIR/.rocm_just_installed"  # marker for end-of-install reboot
        ;;
    esac
  done
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
  
  # Verify source files exist BEFORE copy
  for SRC_FILE in comfyui-launcher.sh stopcomfy.sh watchdog_comfy.sh ezmodl.sh detect_browser.sh; do
    if [ ! -f "$SCRIPT_DIR/$SRC_FILE" ]; then
      log "ERROR: source file $SRC_FILE missing in $SCRIPT_DIR"
      zenity --error --title="Install package incomplete" \
        --text="❌ Source file missing:\n$SCRIPT_DIR/$SRC_FILE\n\nThe install package is incomplete.\nPlease re-clone the repo:\n  git clone $REPO_URL" \
        --width=500 2>/dev/null
      exit 1
    fi
    cp "$SCRIPT_DIR/$SRC_FILE" "$COMFYUI_DIR/" || {
      log "ERROR: failed to copy $SRC_FILE to $COMFYUI_DIR/"
      exit 1
    }
  done
  chmod +x "$COMFYUI_DIR/comfyui-launcher.sh" "$COMFYUI_DIR/stopcomfy.sh" \
           "$COMFYUI_DIR/watchdog_comfy.sh" "$COMFYUI_DIR/ezmodl.sh" \
           "$COMFYUI_DIR/detect_browser.sh"

  # Symlink comfy-models in custom parent (if custom location)
  if [ -n "$CUSTOM_PARENT" ]; then
    log "Setting up comfy-models symlink in $CUSTOM_PARENT..."
    SYMLINK_PATH="$CUSTOM_PARENT/comfy-models"
    REAL_TARGET="$COMFY_DIR/models"
    
    # Ensure the target exists (ComfyUI creates it during install)
    [ ! -d "$REAL_TARGET" ] && mkdir -p "$REAL_TARGET"
    
    if [ -L "$SYMLINK_PATH" ]; then
      CURRENT_TARGET=$(readlink "$SYMLINK_PATH")
      if [ "$CURRENT_TARGET" != "$REAL_TARGET" ]; then
        log "Symlink exists but points to wrong target — updating"
        rm "$SYMLINK_PATH"
        ln -s "$REAL_TARGET" "$SYMLINK_PATH"
      else
        log "Symlink already correct — nothing to do"
      fi
    elif [ -e "$SYMLINK_PATH" ]; then
      log "WARNING: $SYMLINK_PATH exists and is not a symlink — skipping"
    else
      ln -s "$REAL_TARGET" "$SYMLINK_PATH"
      log "✅ Symlink created: $SYMLINK_PATH → $REAL_TARGET"
    fi
  fi

  DESKTOP="$HOME/Desktop"
  [ ! -d "$DESKTOP" ] && DESKTOP="$HOME/Bureau"

  [ -f "$DESKTOP/ComfyUI.desktop" ] && cp "$DESKTOP/ComfyUI.desktop" "$DESKTOP/ComfyUI.desktop.bak"

  # Copy icons to install dir so .desktop files survive if user deletes the git repo
  ICON_COMFY="utilities-terminal"
  ICON_DLMODEL="utilities-terminal"
  if [ -f "$SCRIPT_DIR/icon.png" ]; then
    cp "$SCRIPT_DIR/icon.png" "$COMFYUI_DIR/icon.png" 2>/dev/null
    ICON_COMFY="$COMFYUI_DIR/icon.png"
  fi
  if [ -f "$SCRIPT_DIR/icon_dlmodel.png" ]; then
    cp "$SCRIPT_DIR/icon_dlmodel.png" "$COMFYUI_DIR/icon_dlmodel.png" 2>/dev/null
    ICON_DLMODEL="$COMFYUI_DIR/icon_dlmodel.png"
  fi

  cat > "$DESKTOP/ComfyUI.desktop" << DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=ComfyUI
Comment=Launch ComfyUI
Exec=$COMFYUI_DIR/comfyui-launcher.sh
Icon=$ICON_COMFY
Terminal=false
Categories=Application;
DESK
  gio set "$DESKTOP/ComfyUI.desktop" metadata::trusted true 2>/dev/null
  chmod +x "$DESKTOP/ComfyUI.desktop"

  cat > "$DESKTOP/EZMoDL.desktop" << DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=EZMoDL
Comment=Download a ComfyUI model
Exec=$COMFYUI_DIR/ezmodl.sh
Icon=$ICON_DLMODEL
Terminal=false
Categories=Application;
DESK
  gio set "$DESKTOP/EZMoDL.desktop" metadata::trusted true 2>/dev/null
  chmod +x "$DESKTOP/EZMoDL.desktop"

  log "Desktop shortcuts created"
}

main_install() {
  install_dependencies
  install_comfyui || return 1
  install_scripts
  log "✅ Installation complete!"
  echo "SUCCESS" > "$STATUS_FILE"
}

# ============================================================
# Flow
# ============================================================

# 1) Pre-check (silent, populates MISSING and REASONS)
pre_check

# 2) Build adaptive welcome message
MSG_WELCOME="🚀 Welcome to ComfyUI Installer\n\nWhat will be done on your system:\n\n"

if [ -n "$REASONS" ]; then
  MSG_WELCOME+="⚠️ Compatibility notes:$REASONS\n\n"
fi

if [ -n "$MISSING" ]; then
  MSG_WELCOME+="📦 To install:\n"
  for dep in $MISSING; do
    case $dep in
      rocm)         MSG_WELCOME+="   • ROCm 7.2.2 (~10 GB) — repo.radeon.com\n" ;;
      python3)      MSG_WELCOME+="   • Python 3 + venv — apt official\n" ;;
      python3-venv) MSG_WELCOME+="   • Python venv — apt official\n" ;;
      git)          MSG_WELCOME+="   • Git — apt official\n" ;;
    esac
  done
  MSG_WELCOME+="\n"
fi

MSG_WELCOME+="📦 ComfyUI in ~/ComfyUI (~3 GB)\n   github.com/comfyanonymous/ComfyUI\n\n"
MSG_WELCOME+="🐍 Python venv with PyTorch ROCm (~5 GB)\n   pytorch.org official wheel\n\n"
MSG_WELCOME+="⏳ Total time: ~10-15 minutes\n\n"
MSG_WELCOME+="All sources are official. No third-party mirrors.\n"

# 3) WELCOME ↔ INSTALL LOCATION state machine (Back supported)
STATE="welcome"
while true; do
  case "$STATE" in
    welcome)
      zenity --question --title="ComfyUI Setup" \
        --text="$MSG_WELCOME" \
        --ok-label="✅ Continue" --cancel-label="❌ Cancel" \
        --width=550 2>/dev/null
      [ $? -ne 0 ] && exit 0
      STATE="install_location"
      ;;
    
    install_location)
      LOC_MSG="📁 Where to install ComfyUI scripts?\n\n"
      LOC_MSG+="Default location:\n"
      LOC_MSG+="  ~/.comfyui/   (hidden, standard Linux convention)\n\n"
      LOC_MSG+="Or choose a custom parent folder where we'll create:\n"
      LOC_MSG+="  <your-folder>/comfyui/   (scripts)\n"
      LOC_MSG+="  <your-folder>/comfy-models   (symlink → ~/ComfyUI/models)\n\n"
      LOC_MSG+="Note: the symlink is just a shortcut to the real model folder.\n"
      LOC_MSG+="You can drag-and-drop .safetensors files, organize sub-folders\n"
      LOC_MSG+="(checkpoints, vae, lora, controlnet) from your file manager."
      
      LOC_RES=$(zenity --question --title="Install location" --text="$LOC_MSG" \
        --ok-label="✅ Default" --cancel-label="← Back" \
        --extra-button="📁 Custom location" \
        --width=580 2>/dev/null)
      LOC_CODE=$?
      
      if [ "$LOC_RES" = "📁 Custom location" ]; then
        CUSTOM_PARENT=$(zenity --file-selection --directory \
          --title="Choose parent folder for ComfyUI" \
          --filename="$HOME/" 2>/dev/null)
        if [ -z "$CUSTOM_PARENT" ]; then
          STATE="install_location"
          continue
        fi
        if [ ! -d "$CUSTOM_PARENT" ]; then
          zenity --warning --title="Invalid folder" \
            --text="The selected folder doesn't exist:\n$CUSTOM_PARENT" \
            --width=400 2>/dev/null
          STATE="install_location"
          continue
        fi
        COMFYUI_DIR="$CUSTOM_PARENT/comfyui"
        mkdir -p "$COMFYUI_DIR"
        # Update LOG_FILE path (was set with old COMFYUI_DIR)
        LOG_FILE="$COMFYUI_DIR/install_comfyui.log"
        STATE="proceed"
      elif [ $LOC_CODE -eq 0 ]; then
        # Default
        COMFYUI_DIR="$DEFAULT_COMFYUI_DIR"
        mkdir -p "$COMFYUI_DIR"
        LOG_FILE="$COMFYUI_DIR/install_comfyui.log"
        STATE="proceed"
      else
        # Back
        STATE="welcome"
      fi
      ;;
    
    proceed)
      break
      ;;
  esac
done

# Re-init log with final path (and write Custom Parent if applicable)
cat > "$LOG_FILE" << LOG_EOF
============================================
 ComfyUI — Installation log
 Version: $VERSION
 Date: $(date)
 System: $(uname -a)
 Distro: $(lsb_release -d 2>/dev/null | cut -f2)
 Install dir: $COMFYUI_DIR
LOG_EOF
[ -n "$CUSTOM_PARENT" ] && echo " Custom parent: $CUSTOM_PARENT" >> "$LOG_FILE"
echo "============================================" >> "$LOG_FILE"

# 4) Run install in background
main_install &
INSTALL_PID=$!

# 5) Show pulsate progress with rotating tips
(
  mapfile -t LOCAL_TIPS < "$TIPS_FILE"
  TIPS_COUNT=${#LOCAL_TIPS[@]}
  TIP_INDEX=0
  STEP_DURATION=8     # show step for 8 seconds
  TIP_DURATION=8      # show tip for 8 seconds
  STATE="step"
  PHASE_START=$(date +%s)

  while kill -0 $INSTALL_PID 2>/dev/null; do
    NOW=$(date +%s)
    ELAPSED=$((NOW - PHASE_START))

    if [ "$STATE" = "step" ] && [ $ELAPSED -ge $STEP_DURATION ]; then
      STATE="tip"
      PHASE_START=$NOW
    elif [ "$STATE" = "tip" ] && [ $ELAPSED -ge $TIP_DURATION ]; then
      STATE="step"
      TIP_INDEX=$(( (TIP_INDEX + 1) % TIPS_COUNT ))
      PHASE_START=$NOW
    fi

    if [ "$STATE" = "step" ]; then
      MSG=$(detect_current_step "$LOG_FILE")
    else
      MSG="${LOCAL_TIPS[$TIP_INDEX]}"
    fi

    echo "#${MSG}"
    sleep 1
  done
) | zenity --progress \
    --title="ComfyUI Setup — Installing..." \
    --text="Starting up..." \
    --pulsate --auto-close --no-cancel \
    --width=550 --height=180 \
    2>/dev/null &
ZENITY_PID=$!

# 6) Wait for install to finish
wait $INSTALL_PID 2>/dev/null
kill $ZENITY_PID 2>/dev/null

STATUS=$(cat "$STATUS_FILE" 2>/dev/null)

# 7) Final popup — adaptive (reboot vs launch now)
if [ "$STATUS" = "SUCCESS" ]; then
  if [ -f "$COMFYUI_DIR/.rocm_just_installed" ]; then
    rm -f "$COMFYUI_DIR/.rocm_just_installed"

    MSG_REBOOT="✅ Installation complete!\n\nROCm has been installed for AMD GPU support.\n\n⚠️ A reboot is required for GPU access.\n\nAfter reboot, just double-click the 'ComfyUI' icon on your desktop — everything will be ready to enjoy!\n\nReboot now?"

    if zenity --question --title="ComfyUI Setup — Reboot needed" --text="$MSG_REBOOT" \
         --ok-label="✅ Reboot now" --cancel-label="Later" --width=500 2>/dev/null; then
      sudo reboot
    else
      zenity --info --title="ComfyUI Setup" \
        --text="✅ Install done.\n\nDon't forget to reboot before using ComfyUI." \
        --width=400 2>/dev/null
    fi
  else
    MSG_SUCCESS="✅ ComfyUI installed successfully!\n\nShortcuts 'ComfyUI' and 'EZMoDL' created on desktop.\n\nLaunch ComfyUI now?"
    if zenity --question --title="ComfyUI Setup" --text="$MSG_SUCCESS" \
         --ok-label="✅ Launch now" --cancel-label="Later" --width=450 2>/dev/null; then
      nohup "$COMFYUI_DIR/comfyui-launcher.sh" >/dev/null 2>&1 &
      disown
      echo "Install done — launching ComfyUI"
    else
      echo "Install done — launch later from desktop shortcut"
    fi
  fi
else
  zenity --error --title="ComfyUI Setup" --text="$MSG_FAIL" \
    --extra-button="View log" --width=450 2>/dev/null
  [ $? -eq 1 ] && zenity --text-info --title="Log" --filename="$LOG_FILE" --width=800 --height=500 2>/dev/null
fi

exit 0
