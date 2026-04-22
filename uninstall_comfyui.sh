#!/bin/bash

LANG_SYS=$(echo $LANG | cut -d_ -f1)
if [ "$LANG_SYS" = "fr" ]; then
  MSG="⚠️ Voulez-vous désinstaller ComfyUI ?\n\nCeci supprimera :\n• Le dossier ~/comfyui_propre\n• Les scripts et raccourcis\n\n⚠️ Vos modèles dans ~/comfyui_propre/ComfyUI/models/ seront supprimés !\nVoulez-vous les conserver ?"
  MSG_KEEP="Conserver les modèles"
  MSG_DELETE="Tout supprimer"
  MSG_OK="✅ ComfyUI désinstallé !"
  MSG_MODELS="Vos modèles ont été conservés dans ~/comfyui_models_backup"
else
  MSG="⚠️ Do you want to uninstall ComfyUI?\n\nThis will remove:\n• The ~/comfyui_propre folder\n• Scripts and shortcuts\n\n⚠️ Your models in ~/comfyui_propre/ComfyUI/models/ will be deleted!\nDo you want to keep them?"
  MSG_KEEP="Keep models"
  MSG_DELETE="Delete everything"
  MSG_OK="✅ ComfyUI uninstalled!"
  MSG_MODELS="Your models have been saved to ~/comfyui_models_backup"
fi

# Confirmation
zenity --question --title="AMD AI Setup — Désinstallation ComfyUI" \
  --text="$MSG" --width=450 2>/dev/null
[ $? -ne 0 ] && exit 0

# Sauvegarder les modèles ?
KEEP_MODELS=false
zenity --question --title="Modèles ComfyUI" \
  --text="Voulez-vous sauvegarder vos modèles avant la désinstallation ?" \
  --ok-label="$MSG_KEEP" --cancel-label="$MSG_DELETE" --width=400 2>/dev/null
[ $? -eq 0 ] && KEEP_MODELS=true

(
  echo "10:Arrêt de ComfyUI..."
  pkill -f "python main.py" 2>/dev/null
  pkill -f "watchdog_comfy" 2>/dev/null
  sleep 2

  if [ "$KEEP_MODELS" = true ]; then
    echo "30:Sauvegarde des modèles..."
    cp -r ~/comfyui_propre/ComfyUI/models ~/comfyui_models_backup 2>/dev/null
  fi

  echo "50:Suppression de ComfyUI..."
  rm -rf ~/comfyui_propre

  echo "70:Suppression des scripts..."
  rm -f ~/comfyui_propre/comfyui.sh
  rm -f ~/comfyui_propre/stopcomfy.sh
  rm -f ~/telecharger_modele.sh

  echo "85:Suppression des raccourcis bureau..."
  rm -f ~/Bureau/ComfyUI.desktop ~/Desktop/ComfyUI.desktop
  rm -f ~/Bureau/DL-Modele.desktop ~/Desktop/DL-Modele.desktop

  echo "100:Terminé !"
) | zenity --progress \
  --title="Désinstallation ComfyUI" \
  --text="Désinstallation en cours..." \
  --percentage=0 --auto-close --width=450 2>/dev/null

MSG_FINAL="$MSG_OK"
[ "$KEEP_MODELS" = true ] && MSG_FINAL="$MSG_OK\n\n$MSG_MODELS"
zenity --info --title="AMD AI Setup" --text="$MSG_FINAL" --width=400 2>/dev/null
