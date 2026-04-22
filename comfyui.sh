#!/bin/bash

error_popup() {
  zenity --error --title="ComfyUI — Erreur" --text="$1" --extra-button="Voir les logs" --width=400 2>/dev/null
  if [ $? -eq 1 ]; then
    zenity --text-info --title="Logs ComfyUI" --filename=/home/ia/comfyui.log --width=700 --height=400 2>/dev/null
  fi
}

if pgrep -f "python main.py" > /dev/null; then
  echo "ComfyUI est déjà en cours d'exécution !"
  xdg-open http://localhost:8188
  exit 0
fi

FIREFOX_PROFILE="/home/ia/snap/firefox/common/.mozilla/firefox/comfyui-profile"
mkdir -p "$FIREFOX_PROFILE"

source /home/ia/comfyui_propre/venv/bin/activate
cd /home/ia/comfyui_propre/ComfyUI/
python main.py --listen 0.0.0.0 > /home/ia/comfyui.log 2>&1 &
COMFY_PID=$!

sleep 5

if ! kill -0 $COMFY_PID 2>/dev/null; then
  error_popup "❌ ComfyUI a planté au démarrage.\nVérifiez les logs pour plus de détails."
  exit 1
fi

/home/ia/comfyui_propre/watchdog_comfy.sh > /home/ia/comfyui_watchdog.log 2>&1 &

BROWSER=$(/home/ia/detect_browser.sh | cut -d'|' -f1)
echo "Navigateur détecté : $BROWSER"

case "$BROWSER" in
  firefox)
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

echo "Navigateur fermé, arrêt de ComfyUI..."
/home/ia/comfyui_propre/stopcomfy.sh
