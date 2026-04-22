#!/bin/bash
echo "Arrêt de ComfyUI..."
pkill -f "python main.py"
pkill -f "watchdog_comfy.sh"
echo "Modèles déchargés et ComfyUI arrêté."
