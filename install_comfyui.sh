#!/bin/bash
# ============================================================
#  install_comfyui.sh
#  Installateur ComfyUI (AMD ROCm)
#  Bilingue FR/EN — Interface graphique zenity
#  Testé sur Ubuntu 24.04 / RX 9070 XT / ROCm 7.2
# ============================================================

LOG_FILE="$HOME/install_comfyui.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/comfyui_propre"
VENV_DIR="$INSTALL_DIR/venv"
COMFY_DIR="$INSTALL_DIR/ComfyUI"

# --- Langue ---
LANG_SYS=$(echo $LANG | cut -d_ -f1)
if [ "$LANG_SYS" = "fr" ]; then
  MSG_WELCOME="Bienvenue dans l'installateur ComfyUI\n\nCet outil va installer :\n• ComfyUI (génération d'images par IA)\n• PyTorch avec accélération GPU AMD ROCm\n• Scripts de démarrage et watchdog\n\nConfiguration requise :\n• Ubuntu 24.04\n• GPU AMD avec ROCm\n• Python 3.12\n• Connexion internet\n\nLog : $LOG_FILE"
  MSG_GPU_ERR="❌ Aucun GPU AMD détecté.\n\n/dev/kfd est introuvable.\nVérifiez que vos pilotes AMD ROCm sont installés.\n\nVoulez-vous installer ROCm maintenant ?"
  MSG_PYTHON_ERR="Python3 n'est pas installé.\nVoulez-vous l'installer maintenant ?"
  MSG_GIT_ERR="Git n'est pas installé.\nVoulez-vous l'installer maintenant ?"
  MSG_ROCM_MISSING="Les pilotes AMD ROCm ne sont pas installés.\nVoulez-vous les installer maintenant ?\n\n⚠️ Cela peut prendre 10-20 minutes."
  MSG_SUCCESS="✅ ComfyUI installé avec succès !\n\nUn raccourci 'ComfyUI' a été créé sur votre bureau.\n\n⚠️ Pour les GPU RDNA4 (RX 9070 / 9070 XT) :\nHSA_OVERRIDE_GFX_VERSION=12.0.1 est déjà configuré.\n\nVoulez-vous lancer ComfyUI maintenant ?"
  MSG_FAIL="❌ L'installation a échoué.\n\nConsultez le log ici :\n$LOG_FILE"
  MSG_REBOOT="⚠️ Un redémarrage est nécessaire pour finaliser l'installation des pilotes.\nRedémarrer maintenant ?"
  MSG_VIEW_LOG="Voir le log"
  MSG_SAVE_LOG="Sauvegarder le log"
  MSG_CANCEL="Installation annulée."
else
  MSG_WELCOME="Welcome to the ComfyUI installer\n\nThis tool will install:\n• ComfyUI (AI image generation)\n• PyTorch with AMD ROCm GPU acceleration\n• Launch scripts and watchdog\n\nRequirements:\n• Ubuntu 24.04\n• AMD GPU with ROCm\n• Python 3.12\n• Internet connection\n\nLog: $LOG_FILE"
  MSG_GPU_ERR="❌ No AMD GPU detected.\n\n/dev/kfd not found.\nPlease check that AMD ROCm drivers are installed.\n\nDo you want to install ROCm now?"
  MSG_PYTHON_ERR="Python3 is not installed.\nDo you want to install it now?"
  MSG_GIT_ERR="Git is not installed.\nDo you want to install it now?"
  MSG_ROCM_MISSING="AMD ROCm drivers are not installed.\nDo you want to install them now?\n\n⚠️ This may take 10-20 minutes."
  MSG_SUCCESS="✅ ComfyUI installed successfully!\n\nA 'ComfyUI' shortcut has been created on your desktop.\n\n⚠️ For RDNA4 GPUs (RX 9070 / 9070 XT):\nHSA_OVERRIDE_GFX_VERSION=12.0.1 is already configured.\n\nDo you want to launch ComfyUI now?"
  MSG_FAIL="❌ Installation failed.\n\nSee the log here:\n$LOG_FILE"
  MSG_REBOOT="⚠️ A reboot is required to finalize driver installation.\nReboot now?"
  MSG_VIEW_LOG="View log"
  MSG_SAVE_LOG="Save log"
  MSG_CANCEL="Installation cancelled."
fi

# --- Fonctions ---
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
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
      zenity --info --title="Log sauvegardé" --text="Log sauvegardé dans :\n$DEST" --width=350 2>/dev/null
      ;;
  esac
  exit 1
}

# --- Init log ---
echo "============================================" > "$LOG_FILE"
echo " ComfyUI — Log d'installation"              >> "$LOG_FILE"
echo " $(date)"                                    >> "$LOG_FILE"
echo " Système : $(uname -a)"                      >> "$LOG_FILE"
echo " Ubuntu  : $(lsb_release -d 2>/dev/null | cut -f2)" >> "$LOG_FILE"
echo "============================================" >> "$LOG_FILE"

# --- Zenity disponible ? ---
if ! command -v zenity &>/dev/null; then
  sudo apt install zenity -y >> "$LOG_FILE" 2>&1
fi

# --- Bienvenue ---
zenity --info \
  --title="ComfyUI Setup" \
  --text="$MSG_WELCOME" \
  --width=500 2>/dev/null
[ $? -ne 0 ] && echo "$MSG_CANCEL" && exit 0

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
      echo "5:Téléchargement du paquet AMD..."
      wget -q "https://repo.radeon.com/amdgpu-install/6.3.3/ubuntu/noble/amdgpu-install_6.3.60303-1_all.deb" \
        -O /tmp/amdgpu-install.deb >> "$LOG_FILE" 2>&1
      echo "30:Installation du dépôt AMD..."
      sudo apt install /tmp/amdgpu-install.deb -y >> "$LOG_FILE" 2>&1
      echo "50:Installation ROCm..."
      sudo amdgpu-install --usecase=rocm,hip --no-dkms -y >> "$LOG_FILE" 2>&1
      echo "90:Configuration des groupes..."
      sudo usermod -aG render,video $USER >> "$LOG_FILE" 2>&1
      echo "100:ROCm installé !"
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

# --- Installation ComfyUI ---
(
  echo "5:Création des dossiers..."
  mkdir -p "$INSTALL_DIR"
  log "Dossier : $INSTALL_DIR"

  echo "10:Clonage de ComfyUI depuis GitHub..."
  if [ ! -d "$COMFY_DIR" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR" >> "$LOG_FILE" 2>&1 \
      || { log "ERREUR: git clone ComfyUI"; exit 1; }
  else
    log "ComfyUI déjà présent, mise à jour..."
    cd "$COMFY_DIR" && git pull >> "$LOG_FILE" 2>&1
  fi

  echo "25:Création de l'environnement Python virtuel..."
  python3 -m venv "$VENV_DIR" >> "$LOG_FILE" 2>&1 \
    || { log "ERREUR: création venv"; exit 1; }
  source "$VENV_DIR/bin/activate"

  echo "30:Mise à jour de pip..."
  pip install --upgrade pip >> "$LOG_FILE" 2>&1

  echo "35:Installation de PyTorch ROCm 7.2 (peut prendre 5-10 min)..."
  pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/rocm7.2 >> "$LOG_FILE" 2>&1 \
    || { log "ERREUR: installation PyTorch ROCm"; exit 1; }

  echo "70:Installation des dépendances ComfyUI..."
  pip install -r "$COMFY_DIR/requirements.txt" >> "$LOG_FILE" 2>&1 \
    || { log "ERREUR: installation requirements ComfyUI"; exit 1; }

  deactivate

  echo "80:Copie des scripts..."
  cp "$SCRIPT_DIR/comfyui.sh" "$INSTALL_DIR/"
  cp "$SCRIPT_DIR/stopcomfy.sh" "$INSTALL_DIR/"
  cp "$SCRIPT_DIR/watchdog_comfy.sh" "$INSTALL_DIR/"
  cp "$SCRIPT_DIR/telecharger_modele.sh" "$HOME/"
  cp "$SCRIPT_DIR/../detect_browser.sh" "$HOME/"
  chmod +x "$INSTALL_DIR/comfyui.sh" \
           "$INSTALL_DIR/stopcomfy.sh" \
           "$INSTALL_DIR/watchdog_comfy.sh" \
           "$HOME/telecharger_modele.sh" \
           "$HOME/detect_browser.sh"

  echo "88:Création du raccourci bureau..."
  DESKTOP="$HOME/Desktop"
  [ ! -d "$DESKTOP" ] && DESKTOP="$HOME/Bureau"
  cat > "$DESKTOP/ComfyUI.desktop" << DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=ComfyUI
Comment=Lancer ComfyUI
Exec=bash -c "$INSTALL_DIR/comfyui.sh > $HOME/comfyui.log 2>&1"
Icon=utilities-terminal
Terminal=false
Categories=Application;
DESK
  gio set "$DESKTOP/ComfyUI.desktop" metadata::trusted true 2>/dev/null
  chmod +x "$DESKTOP/ComfyUI.desktop"

  echo "95:Création du raccourci téléchargement modèles..."
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

  log "OK: ComfyUI installé avec succès"
  echo "100:Installation terminée !"

) | zenity --progress \
  --title="Installation ComfyUI" \
  --text="Installation en cours, veuillez patienter..." \
  --percentage=0 \
  --auto-close \
  --width=500 2>/dev/null || error_exit "Une erreur est survenue pendant l'installation."

# --- Succès ---
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

exit 0
