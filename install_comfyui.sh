#!/bin/bash
# ============================================================
#  install_comfyui.sh
#  Installateur ComfyUI (AMD ROCm)
#  Bilingue FR/EN — Interface graphique zenity
#  Testé sur Ubuntu 24.04 / RX 9070 XT / ROCm 7.2
# ============================================================

LOG_FILE="$HOME/install_comfyui.log"
STATUS_FILE=$(mktemp)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/comfyui_propre"
VENV_DIR="$INSTALL_DIR/venv"
COMFY_DIR="$INSTALL_DIR/ComfyUI"

# --- Zenity disponible ? ---
if ! command -v zenity &>/dev/null; then
  sudo apt install zenity -y
fi

# --- Authentification sudo ---
if ! sudo -n true 2>/dev/null; then
  PASSWORD=$(zenity --password \
    --title="Authentification requise" \
    --text="Entrez votre mot de passe pour installer ComfyUI :" \
    --width=400 2>/dev/null)
  [ $? -ne 0 ] && exit 0
  echo "$PASSWORD" | sudo -S -v 2>/dev/null || {
    zenity --error --title="Erreur" --text="❌ Mot de passe incorrect." --width=300 2>/dev/null
    exit 1
  }
fi

# --- Langue ---
LANG_SYS=$(echo $LANG | cut -d_ -f1)
if [ "$LANG_SYS" = "fr" ]; then
  MSG_WELCOME="Bienvenue dans l'installateur ComfyUI\n\nCet outil va installer :\n• ComfyUI (génération d'images par IA)\n• PyTorch avec accélération GPU AMD ROCm\n• Scripts de démarrage et watchdog\n\nConfiguration requise :\n• Ubuntu 24.04\n• GPU AMD avec ROCm\n• Python 3.12\n• Connexion internet\n\n⏳ L'installation peut prendre 10-20 minutes.\n\nLog : $LOG_FILE"
  MSG_GPU_ERR="❌ Aucun GPU AMD détecté.\n\n/dev/kfd est introuvable.\nVérifiez que vos pilotes AMD ROCm sont installés.\n\nVoulez-vous installer ROCm maintenant ?"
  MSG_PYTHON_ERR="Python3 n'est pas installé.\nVoulez-vous l'installer maintenant ?"
  MSG_GIT_ERR="Git n'est pas installé.\nVoulez-vous l'installer maintenant ?"
  MSG_SUCCESS="✅ ComfyUI installé avec succès !\n\nUn raccourci 'ComfyUI' a été créé sur votre bureau.\n\n⚠️ Pour les GPU RDNA4 (RX 9070 / 9070 XT) :\nHSA_OVERRIDE_GFX_VERSION=12.0.1 est déjà configuré.\n\nVoulez-vous lancer ComfyUI maintenant ?"
  MSG_FAIL="❌ L'installation a échoué.\n\nConsultez le log ici :\n$LOG_FILE"
  MSG_REBOOT="⚠️ Un redémarrage est nécessaire pour finaliser l'installation des pilotes.\nRedémarrer maintenant ?"
  MSG_SHORTCUT_EXISTS="Un raccourci ComfyUI existe déjà sur le bureau.\nVoulez-vous le remplacer ?\n\n(L'ancien sera sauvegardé en .bak)"
  MSG_VIEW_LOG="Voir le log"
  MSG_SAVE_LOG="Sauvegarder le log"
  MSG_CANCEL="Installation annulée."
  MSG_ABORT="Abandonner l'installation ?"
else
  MSG_WELCOME="Welcome to the ComfyUI installer\n\nThis tool will install:\n• ComfyUI (AI image generation)\n• PyTorch with AMD ROCm GPU acceleration\n• Launch scripts and watchdog\n\nRequirements:\n• Ubuntu 24.04\n• AMD GPU with ROCm\n• Python 3.12\n• Internet connection\n\n⏳ Installation may take 10-20 minutes.\n\nLog: $LOG_FILE"
  MSG_GPU_ERR="❌ No AMD GPU detected.\n\n/dev/kfd not found.\nPlease check that AMD ROCm drivers are installed.\n\nDo you want to install ROCm now?"
  MSG_PYTHON_ERR="Python3 is not installed.\nDo you want to install it now?"
  MSG_GIT_ERR="Git is not installed.\nDo you want to install it now?"
  MSG_SUCCESS="✅ ComfyUI installed successfully!\n\nA 'ComfyUI' shortcut has been created on your desktop.\n\n⚠️ For RDNA4 GPUs (RX 9070 / 9070 XT):\nHSA_OVERRIDE_GFX_VERSION=12.0.1 is already configured.\n\nDo you want to launch ComfyUI now?"
  MSG_FAIL="❌ Installation failed.\n\nSee the log here:\n$LOG_FILE"
  MSG_REBOOT="⚠️ A reboot is required to finalize driver installation.\nReboot now?"
  MSG_SHORTCUT_EXISTS="A ComfyUI shortcut already exists on the desktop.\nDo you want to replace it?\n\n(The old one will be saved as .bak)"
  MSG_VIEW_LOG="View log"
  MSG_SAVE_LOG="Save log"
  MSG_CANCEL="Installation cancelled."
  MSG_ABORT="Abort installation?"
fi

# --- Fonctions ---
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

error_exit() {
  echo "ERROR" > "$STATUS_FILE"
  log "ERREUR: $1"
  zenity --error \
    --title="ComfyUI Setup — Erreur" \
    --text="$MSG_FAIL" \
    --extra-button="$MSG_VIEW_LOG" \
    --extra-button="$MSG_SAVE_LOG" \
    --width=450 2>/dev/null
  case $? in
    1) zenity --text-info --title="Log" --filename="$LOG_FILE" --width=800 --height=500 2>/dev/null ;;
    2)
      DEST="$HOME/Desktop/install_comfyui.log"
      [ ! -d "$HOME/Desktop" ] && DEST="$HOME/Bureau/install_comfyui.log"
      cp "$LOG_FILE" "$DEST"
      ;;
  esac
  rm -f "$STATUS_FILE"
  exit 1
}

# --- Init log ---
echo "============================================" > "$LOG_FILE"
echo " ComfyUI — Log d'installation"              >> "$LOG_FILE"
echo " $(date)"                                    >> "$LOG_FILE"
echo " Système : $(uname -a)"                      >> "$LOG_FILE"
echo " Ubuntu  : $(lsb_release -d 2>/dev/null | cut -f2)" >> "$LOG_FILE"
echo "============================================" >> "$LOG_FILE"

# --- Bienvenue ---
zenity --info \
  --title="ComfyUI Setup" \
  --text="$MSG_WELCOME" \
  --width=500 2>/dev/null
[ $? -ne 0 ] && exit 0

# --- Vérification Python ---
if ! command -v python3 &>/dev/null; then
  zenity --question --title="ComfyUI Setup" --text="$MSG_PYTHON_ERR" --width=400 2>/dev/null
  if [ $? -eq 0 ]; then
    sudo apt install python3 python3-venv python3-pip -y >> "$LOG_FILE" 2>&1
    log "OK: Python3 installé"
  else
    error_exit "Python3 requis mais non installé."
  fi
fi

# --- Vérification Git ---
if ! command -v git &>/dev/null; then
  zenity --question --title="ComfyUI Setup" --text="$MSG_GIT_ERR" --width=400 2>/dev/null
  if [ $? -eq 0 ]; then
    sudo apt install git -y >> "$LOG_FILE" 2>&1
    log "OK: Git installé"
  else
    error_exit "Git requis mais non installé."
  fi
fi

# --- Vérification ROCm / GPU ---
if [ ! -e /dev/kfd ]; then
  zenity --question \
    --title="ComfyUI Setup" \
    --text="$MSG_GPU_ERR" \
    --width=450 2>/dev/null
  if [ $? -eq 0 ]; then
    (
      echo "5"; echo "# Téléchargement du paquet AMD..."
      wget -q "https://repo.radeon.com/amdgpu-install/6.3.3/ubuntu/noble/amdgpu-install_6.3.60303-1_all.deb" \
        -O /tmp/amdgpu-install.deb >> "$LOG_FILE" 2>&1
      echo "30"; echo "# Installation du dépôt AMD..."
      sudo apt install /tmp/amdgpu-install.deb -y >> "$LOG_FILE" 2>&1
      echo "50"; echo "# Installation ROCm..."
      sudo amdgpu-install --usecase=rocm,hip --no-dkms -y >> "$LOG_FILE" 2>&1
      echo "90"; echo "# Configuration des groupes..."
      sudo usermod -aG render,video $USER >> "$LOG_FILE" 2>&1
      echo "100"; echo "# ROCm installé !"
    ) | zenity --progress \
      --title="Installation ROCm" \
      --text="Installation des pilotes AMD ROCm..." \
      --percentage=0 --auto-close --width=450 2>/dev/null
    log "OK: ROCm installé"
    zenity --question --title="ComfyUI Setup" --text="$MSG_REBOOT" --width=400 2>/dev/null
    [ $? -eq 0 ] && sudo reboot
    exit 0
  else
    error_exit "GPU AMD requis mais non détecté."
  fi
fi

# --- Lancer l'installation en arrière-plan ---
install_comfyui() {
  log "=== Démarrage installation ComfyUI ==="

  log "Création des dossiers..."
  mkdir -p "$INSTALL_DIR"

  log "Clonage de ComfyUI depuis GitHub..."
  if [ ! -d "$COMFY_DIR" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR" >> "$LOG_FILE" 2>&1 \
      || { error_exit "git clone ComfyUI échoué"; return 1; }
  else
    log "ComfyUI déjà présent, mise à jour..."
    cd "$COMFY_DIR" && git pull >> "$LOG_FILE" 2>&1
  fi

  log "Création de l'environnement Python..."
  python3 -m venv "$VENV_DIR" >> "$LOG_FILE" 2>&1 \
    || { error_exit "création venv échouée"; return 1; }
  source "$VENV_DIR/bin/activate"

  log "Mise à jour de pip..."
  pip install --upgrade pip >> "$LOG_FILE" 2>&1

  log "⏳ Téléchargement PyTorch ROCm (~6 GB, patience)..."
  pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/rocm7.2 >> "$LOG_FILE" 2>&1 \
    || { error_exit "installation PyTorch ROCm échouée"; return 1; }

  log "Installation des dépendances ComfyUI..."
  pip install -r "$COMFY_DIR/requirements.txt" >> "$LOG_FILE" 2>&1 \
    || { error_exit "installation dépendances échouée"; return 1; }

  deactivate

  log "Copie des scripts..."
  cp "$SCRIPT_DIR/comfyui.sh" "$INSTALL_DIR/"
  cp "$SCRIPT_DIR/stopcomfy.sh" "$INSTALL_DIR/"
  cp "$SCRIPT_DIR/watchdog_comfy.sh" "$INSTALL_DIR/"
  cp "$SCRIPT_DIR/telecharger_modele.sh" "$HOME/"
  cp "$SCRIPT_DIR/detect_browser.sh" "$HOME/" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/comfyui.sh" \
           "$INSTALL_DIR/stopcomfy.sh" \
           "$INSTALL_DIR/watchdog_comfy.sh" \
           "$HOME/telecharger_modele.sh"

  log "Création des raccourcis bureau..."
  DESKTOP="$HOME/Desktop"
  [ ! -d "$DESKTOP" ] && DESKTOP="$HOME/Bureau"

  CREATE_SHORTCUT=true
  if [ -f "$DESKTOP/ComfyUI.desktop" ]; then
    cp "$DESKTOP/ComfyUI.desktop" "$DESKTOP/ComfyUI.desktop.bak"
    zenity --question --title="ComfyUI Setup" --text="$MSG_SHORTCUT_EXISTS" --width=400 2>/dev/null
    [ $? -ne 0 ] && CREATE_SHORTCUT=false
  fi

  if [ "$CREATE_SHORTCUT" = true ]; then
    cat > "$DESKTOP/ComfyUI.desktop" << DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=ComfyUI
Comment=Lancer ComfyUI
Exec=$INSTALL_DIR/comfyui.sh
Icon=utilities-terminal
Terminal=false
Categories=Application;
DESK
    gio set "$DESKTOP/ComfyUI.desktop" metadata::trusted true 2>/dev/null
    chmod +x "$DESKTOP/ComfyUI.desktop"
  fi

  cat > "$DESKTOP/DL-Modele.desktop" << DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=DL Modèle
Comment=Télécharger un modèle ComfyUI
Exec=$HOME/telecharger_modele.sh
Icon=emblem-downloads
Terminal=true
Categories=Application;
DESK
  gio set "$DESKTOP/DL-Modele.desktop" metadata::trusted true 2>/dev/null
  chmod +x "$DESKTOP/DL-Modele.desktop"

  log "✅ Installation ComfyUI terminée avec succès !"
  echo "SUCCESS" > "$STATUS_FILE"
}

# Lancer l'installation en arrière-plan
install_comfyui &
INSTALL_PID=$!

# Afficher les logs en temps réel avec bouton Abandonner
tail -f "$LOG_FILE" 2>/dev/null | zenity --text-info \
  --title="ComfyUI Setup — Installation en cours..." \
  --width=700 --height=400 \
  --no-wrap \
  --cancel-label="Abandonner" \
  --ok-label="Fermer" 2>/dev/null &
ZENITY_PID=$!

# Surveiller la fin de l'installation
while kill -0 $INSTALL_PID 2>/dev/null; do
  # Si l'utilisateur a cliqué Abandonner
  if ! kill -0 $ZENITY_PID 2>/dev/null; then
    zenity --question \
      --title="ComfyUI Setup" \
      --text="$MSG_ABORT" \
      --width=350 2>/dev/null
    if [ $? -eq 0 ]; then
      kill $INSTALL_PID 2>/dev/null
      rm -f "$STATUS_FILE"
      exit 0
    else
      # Rouvrir la fenêtre de log
      tail -f "$LOG_FILE" 2>/dev/null | zenity --text-info \
        --title="ComfyUI Setup — Installation en cours..." \
        --width=700 --height=400 \
        --no-wrap \
        --cancel-label="Abandonner" \
        --ok-label="Fermer" 2>/dev/null &
      ZENITY_PID=$!
    fi
  fi
  sleep 1
done

# Fermer zenity log
kill $ZENITY_PID 2>/dev/null

# Vérifier le résultat
STATUS=$(cat "$STATUS_FILE" 2>/dev/null)
rm -f "$STATUS_FILE"

if [ "$STATUS" = "SUCCESS" ]; then
  zenity --info \
    --title="ComfyUI Setup" \
    --text="$MSG_SUCCESS" \
    --extra-button="$MSG_VIEW_LOG" \
    --extra-button="$MSG_SAVE_LOG" \
    --width=500 2>/dev/null

  case $? in
    0) bash "$INSTALL_DIR/comfyui.sh" & ;;
    1) zenity --text-info --title="Log" --filename="$LOG_FILE" --width=800 --height=500 2>/dev/null ;;
    2)
      DEST="$HOME/Desktop/install_comfyui.log"
      [ ! -d "$HOME/Desktop" ] && DEST="$HOME/Bureau/install_comfyui.log"
      cp "$LOG_FILE" "$DEST"
      zenity --info --title="Log sauvegardé" --text="Log sauvegardé dans :\n$DEST" --width=350 2>/dev/null
      ;;
  esac
else
  zenity --error \
    --title="ComfyUI Setup — Erreur" \
    --text="$MSG_FAIL" \
    --extra-button="$MSG_VIEW_LOG" \
    --extra-button="$MSG_SAVE_LOG" \
    --width=450 2>/dev/null
  case $? in
    1) zenity --text-info --title="Log" --filename="$LOG_FILE" --width=800 --height=500 2>/dev/null ;;
    2)
      DEST="$HOME/Desktop/install_comfyui.log"
      [ ! -d "$HOME/Desktop" ] && DEST="$HOME/Bureau/install_comfyui.log"
      cp "$LOG_FILE" "$DEST"
      ;;
  esac
fi

exit 0
