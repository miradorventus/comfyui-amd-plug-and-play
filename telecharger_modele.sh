#!/bin/bash

echo "================================"
echo "  Téléchargeur de modèles ComfyUI"
echo "================================"
echo ""
echo "Colle l'URL du modèle :"
read URL

echo ""
echo "Où télécharger ?"
echo "  1) checkpoints"
echo "  2) loras"
echo "  3) vae"
echo "  4) controlnet"
echo "  5) upscale_models"
echo "  6) embeddings"
echo "  7) text_encoders"
echo "  8) diffusion_models"
read -p "Choix [1-8] : " CHOIX

case $CHOIX in
  1) DEST="checkpoints" ;;
  2) DEST="loras" ;;
  3) DEST="vae" ;;
  4) DEST="controlnet" ;;
  5) DEST="upscale_models" ;;
  6) DEST="embeddings" ;;
  7) DEST="text_encoders" ;;
  8) DEST="diffusion_models" ;;
  *) echo "Choix invalide"; exit 1 ;;
esac

DOSSIER="/home/ia/comfyui_propre/ComfyUI/models/$DEST"
FICHIER=$(basename "$URL" | cut -d'?' -f1)

echo ""
echo "Téléchargement de $FICHIER dans $DEST..."
wget -c "$URL" -O "$DOSSIER/$FICHIER"

echo ""
echo "Terminé ! Modèle disponible dans ComfyUI."
