#!/bin/bash
# Watchdog ComfyUI - décharge les modèles si aucun client connecté
IDLE_TIMEOUT=300  # secondes avant déchargement
last_connected=$(date +%s)
was_connected=false

while true; do
  # Vérifie si un navigateur est connecté sur 8188
  connections=$(ss -tn | grep ':8188' | grep ESTAB | wc -l)

  if [ "$connections" -gt 0 ]; then
    last_connected=$(date +%s)
    was_connected=true
  else
    if [ "$was_connected" = true ]; then
      now=$(date +%s)
      idle=$((now - last_connected))
      if [ "$idle" -ge "$IDLE_TIMEOUT" ]; then
        echo "$(date) - Aucun client depuis ${idle}s, déchargement des modèles..."
        curl -s -X POST http://localhost:8188/free \
          -H "Content-Type: application/json" \
          -d '{"unload_models": true, "free_memory": true}' > /dev/null
        was_connected=false
      fi
    fi
  fi
  sleep 10
done
