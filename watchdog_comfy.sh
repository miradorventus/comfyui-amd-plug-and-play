#!/bin/bash
# ============================================================
#  watchdog_comfy.sh — Free VRAM after 5 min idle
# ============================================================

LAST_ACTIVITY=$(date +%s)
TIMEOUT=300  # 5 minutes

while true; do
  sleep 30
  
  if ! pgrep -f "python main.py" > /dev/null; then
    echo "ComfyUI not running, watchdog exit"
    exit 0
  fi

  STATS=$(curl -s http://localhost:8188/queue 2>/dev/null)
  PENDING=$(echo "$STATS" | grep -o '"queue_running":\[[^]]*\]' | grep -c 'PromptQueue')

  if [ "$PENDING" -gt 0 ] 2>/dev/null; then
    LAST_ACTIVITY=$(date +%s)
    continue
  fi

  NOW=$(date +%s)
  IDLE=$((NOW - LAST_ACTIVITY))

  if [ $IDLE -gt $TIMEOUT ]; then
    echo "Idle for $IDLE seconds, freeing VRAM..."
    curl -s -X POST http://localhost:8188/free \
      -H "Content-Type: application/json" \
      -d '{"unload_models":true,"free_memory":true}' > /dev/null
    LAST_ACTIVITY=$(date +%s)
  fi
done
