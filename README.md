# ComfyUI — AMD ROCm

## Installation
```bash
chmod +x install_comfyui.sh
./install_comfyui.sh
```

## Utilisation
- Lancer : `./comfyui.sh`
- Arrêter : `./stopcomfy.sh`
- Interface : http://localhost:8188
- Télécharger un modèle : `~/telecharger_modele.sh`

## Notes
- HSA_OVERRIDE_GFX_VERSION=12.0.1 requis pour RDNA4
- Watchdog : décharge les modèles après 5 min d'inactivité
