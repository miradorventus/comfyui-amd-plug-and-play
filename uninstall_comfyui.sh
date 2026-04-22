#!/bin/bash

# --- Zenity disponible ? ---
if ! command -v zenity &>/dev/null; then
  sudo apt install zenity -y
fi

# --- Authentification sudo ---
if ! sudo -n true 2>/dev/null; then
  PASSWORD=$(zenity --password \
    --title="Authentification requise" \
    --text="Entrez votre mot de passe administrateur :" \
    --width=400 2>/dev/null)
  [ $? -ne 0 ] && exit 0
  echo "$PASSWORD" | sudo -S -v 2>/dev/null || {
    zenity --error --title="Erreur" --text="❌ Mot de passe incorrect." --width=300 2>/dev/null
    exit 1
  }
fi

LANG_SYS=$(echo $LANG | cut -d_ -f1)
if [ "$LANG_SYS" = "fr" ]; then
  MSG="⚠️ Voulez-vous désinstaller ComfyUI ?\n\nCeci supprimera :\n• Le dossier ~/comfyui_propre\n• Les scripts et raccourcis\n\n⚠️ Vos modèles dans ~/comfyui_propre/ComfyUI/models/ seront supprimés !"
  MSG_KEEP="Conserver les modèles"
  MSG_DELETE="Tout supprimer"
  MSG_OK="✅ ComfyUI désinstallé !"
  MSG_MODELS="Vos modèles ont été conservés dans ~/comfyui_models_backup"
  MSG_CANCEL="Désinstallation annulée."
  MSG_INTERRUPTED="⚠️ Désinstallation interrompue."
else
  MSG="⚠️ Do you want to uninstall ComfyUI?\n\nThis will remove:\n• The ~/comfyui_propre folder\n• Scripts and shortcuts\n\n⚠️ Your models in ~/comfyui_propre/ComfyUI/models/ will be deleted!"
  MSG_KEEP="Keep models"
  MSG_DELETE="Delete everything"
  MSG_OK="✅ ComfyUI uninstalled!"
  MSG_MODELS="Your models have been saved to ~/comfyui_models_backup"
  MSG_CANCEL="Uninstallation cancelled."
  MSG_INTERRUPTED="⚠️ Uninstallation interrupted."
fi

# Confirmation
zenity --question \
  --title="AMD AI Setup — Désinstallation ComfyUI" \
  --text="$MSG" --width=450 2>/dev/null
[ $? -ne 0 ] && echo "$MSG_CANCEL" && exit 0

# Sauvegarder les modèles ?
KEEP_MODELS=false
zenity --question \
  --title="Modèles ComfyUI" \
  --text="Voulez-vous sauvegarder vos modèles avant la désinstallation ?" \
  --ok-label="$MSG_KEEP" \
  --cancel-label="$MSG_DELETE" \
  --width=400 2>/dev/null
[ $? -eq 0 ] && KEEP_MODELS=true

# --- Pipe pour logs en temps réel ---
PIPE=$(mktemp -u)
mkfifo "$PIPE"

zenity --text-info \
  --title="ComfyUI — Désinstallation en cours..." \
  --filename="$PIPE" \
  --width=600 --height=300 \
  --no-wrap 2>/dev/null &
ZENITY_LOG_PID=$!

exec 3>"$PIPE"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&3
}

log "=== Démarrage désinstallation ComfyUI ==="

log "Arrêt de ComfyUI..."
pkill -f "python main.py" 2>/dev/null
pkill -f "watchdog_comfy" 2>/dev/null
sleep 2

if [ "$KEEP_MODELS" = true ]; then
  log "Sauvegarde des modèles dans ~/comfyui_models_backup..."
  cp -r ~/comfyui_propre/ComfyUI/models ~/comfyui_models_backup 2>/dev/null
  log "Modèles sauvegardés ✅"
fi

log "Suppression de ~/comfyui_propre..."
rm -rf ~/comfyui_propre
log "Dossier supprimé ✅"

log "Suppression des scripts..."
rm -f ~/telecharger_modele.sh
log "Scripts supprimés ✅"

log "Suppression des raccourcis bureau..."
rm -f ~/Bureau/ComfyUI.desktop ~/Desktop/ComfyUI.desktop
rm -f ~/Bureau/DL-Modele.desktop ~/Desktop/DL-Modele.desktop
log "Raccourcis supprimés ✅"

log "✅ Désinstallation terminée !"

exec 3>&-
wait $ZENITY_LOG_PID 2>/dev/null
rm -f "$PIPE"

MSG_FINAL="$MSG_OK"
[ "$KEEP_MODELS" = true ] && MSG_FINAL="$MSG_OK\n\n$MSG_MODELS"
zenity --info --title="AMD AI Setup" --text="$MSG_FINAL" --width=400 2>/dev/null

exit 0
