# 🎨 ComfyUI — AMD Plug & Play

> **One click. That's it.**

A dead-simple installer for **ComfyUI** on Ubuntu with AMD GPU acceleration.
No terminal wizardry needed — just double-click and go.

---

## ✨ What you get

- 🖥️ **Desktop shortcut** to launch everything with one click
- 🎨 **ComfyUI** — powerful node-based AI image generation on your AMD GPU
- 📥 **Model downloader** — desktop shortcut to download models easily
- ⚡ **Auto stop** — closes everything when you close the browser
- 💾 **VRAM watchdog** — models unload automatically after 5 minutes idle
- 🔒 **100% local** — your images stay on your machine

---

## 🖥️ Requirements

| Component | Requirement |
|---|---|
| OS | Ubuntu 24.04 LTS |
| GPU | AMD with ROCm support (RX 6000 series and newer) |
| RAM | 16 GB minimum |
| Storage | 25 GB free minimum (PyTorch ROCm is large) |
| Internet | Required for installation only |

> ⚠️ **RDNA4 users (RX 9070 / 9070 XT):** `HSA_OVERRIDE_GFX_VERSION=12.0.1` is already pre-configured.

---

## 📦 Installation

**Copy this 👇 — Paste into a terminal — Press Enter — Enjoy! 🎉**

```bash
git clone https://github.com/miradorventus/comfyui-amd-plug-and-play.git
cd comfyui-amd-plug-and-play
chmod +x install_comfyui.sh
./install_comfyui.sh
```

The graphical installer will handle everything:

1. ✅ Ask for your password once (via a popup — no terminal needed after this)
2. ✅ Check Python, Git and your AMD GPU
3. ✅ Clone ComfyUI from GitHub
4. ✅ Install PyTorch with ROCm acceleration
5. ✅ Create desktop shortcuts **ComfyUI** and **DL Model**
6. ✅ Launch ComfyUI automatically when done

> ⏳ Installation takes **10-20 minutes** — PyTorch ROCm is about 6 GB.
> A live log window shows you exactly what's happening. Don't worry if it seems slow — it's normal!

---

## 🎮 Daily Usage

**Start:** Double-click **ComfyUI** on your desktop

**Stop:** Close the browser window — everything stops automatically

**Web interface:** `http://localhost:8188`

---

## 🗑️ Uninstall

**Copy this 👇 — Paste into a terminal — Done!**

```bash
cd comfyui-amd-plug-and-play
./uninstall_comfyui.sh
```

- Asks if you want to **save your models** before uninstalling
- Removes ComfyUI and its virtual environment
- Removes scripts and desktop shortcuts

---

## 📥 Download a Model

### Option 1 — Desktop shortcut (easiest)

Double-click **DL Model** on your desktop → paste the model URL → choose the folder → done!

**Example URL from HuggingFace:**
```
https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
```

**Example URL from Civitai:**
```
# Go to civitai.com → find a model → click Download → copy the link → paste it into DL Model
```

### Option 2 — Command line

```bash
# Download SD 1.5 (classic, lightweight — 2 GB)
wget -c "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" \
  -O ~/comfyui_propre/ComfyUI/models/checkpoints/v1-5-pruned-emaonly.safetensors

# Download SDXL base (HD images — 7 GB)
wget -c "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" \
  -O ~/comfyui_propre/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors

# Download a LoRA (style add-on — usually 50-200 MB)
wget -c "YOUR_LORA_URL" \
  -O ~/comfyui_propre/ComfyUI/models/loras/my_lora.safetensors
```

### Model Folders

| Folder | What goes there | Example |
|---|---|---|
| `checkpoints/` | Main models | SD 1.5, SDXL, Flux |
| `loras/` | Style add-ons | character LoRA, art style |
| `vae/` | Color improvement | sdxl_vae.safetensors |
| `controlnet/` | Pose/edge control | control_canny.safetensors |
| `upscale_models/` | Image upscaling | RealESRGAN_x4.pth |
| `embeddings/` | Textual styles | bad_hands.pt |
| `text_encoders/` | For Flux models | clip_l.safetensors |

### VRAM Guide

| Your VRAM | Recommended models |
|---|---|
| 4 GB | SD 1.5 at 512×512 |
| 8 GB | SDXL at 1024×1024 |
| 12 GB | Flux schnell (fast generations) |
| 16 GB | Flux dev (best quality) |
| 24 GB+ | Any model, high resolution |

> 💡 Out of memory? Try reducing the image resolution in your workflow, or switch to a smaller model.

---

## 🔧 Useful Commands

**Update ComfyUI:**
```bash
cd ~/comfyui_propre/ComfyUI
source ~/comfyui_propre/venv/bin/activate
git pull
pip install -r requirements.txt
deactivate
```

**Install a custom node:**
```bash
# Example: installing ComfyUI Manager
cd ~/comfyui_propre/ComfyUI/custom_nodes/
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
source ~/comfyui_propre/venv/bin/activate
cd ComfyUI-Manager && pip install -r requirements.txt
deactivate
# Then restart ComfyUI
```

**Check GPU is working:**
```bash
grep "ROCm\|AMD\|gfx" ~/comfyui.log
# Should show: pytorch version: X.X.X+rocm7.2 ✅
```

**View error logs:**
```bash
cat ~/comfyui.log | tail -30
```

See **MEMO.txt** for the full command reference.

---

## 🌐 Where to find models

- 🌐 **Civitai** — https://civitai.com (SD 1.5, SDXL, LoRA, checkpoints)
- 🤗 **HuggingFace** — https://huggingface.co (Flux, SDXL, SD 1.5, everything)
- 📋 **OpenArt Workflows** — https://openart.ai/workflows (ready-to-use workflows)

---

## 💬 Contributing

All feedback is welcome — bugs, suggestions, improvements, anything!

→ Open an **Issue**
→ Submit a **Pull Request**
→ Share your experience

This project is made by a fellow AMD Linux user, for AMD Linux users. 🤝

---

## 📄 License

MIT — Free to use, modify and share.
