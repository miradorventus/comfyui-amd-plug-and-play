<p align="center"><img src="icon.png" width="200"/></p>

# 🎨 ComfyUI — AMD Plug & Play

> **No terminal gymnastics. No dependency hell. Just vibes and working AI.**

You want to generate images on your AMD GPU. You don't want to spend the afternoon debugging PyTorch ROCm wheels, virtual environments, or why `libcuda.so.1` is missing on a card that doesn't even use CUDA.

**One command. One click. ComfyUI running on your AMD GPU.**

---

## ✨ What you get

- 🖥️ **Desktop shortcut** — click it, ComfyUI opens, you generate
- 🎨 **ComfyUI** — node-based image generation, installed clean from the official repo
- 📥 **Model downloader** — paste URL, pick folder from **22 options**, download. Filename stays original (templates rely on that)
- ⚡ **Smart on-demand** — closes when you close the browser
- 💾 **VRAM watchdog** — auto-frees memory after 5 minutes idle
- 📂 **Standard layout** — `~/ComfyUI/` (git repo) and `~/.venvs/comfyui/` (venv). Easy to update with `git pull`
- 🔒 **100% local** — your generations stay on your machine

---

## 🖥️ Requirements

| Component | Requirement |
|---|---|
| OS | Ubuntu 24.04 LTS |
| GPU | AMD with ROCm support (RX 6000 series and newer) |
| RAM | 16 GB minimum |
| Storage | 25 GB free (PyTorch ROCm is chunky, I know) |
| Internet | For the initial setup only |

> ⚠️ **RDNA4 gang (RX 9070 / 9070 XT):** `HSA_OVERRIDE_GFX_VERSION=12.0.1` is already wired up. You're welcome.

---

## 📦 Installation

**Copy this 👇 — Paste into terminal — Go make dinner 🍝**

```bash
git clone https://github.com/miradorventus/comfyui-amd-plug-and-play.git
cd comfyui-amd-plug-and-play
chmod +x install_comfyui.sh
./install_comfyui.sh
```

The installer does the work:

1. ✅ Asks for your password once (popup, not terminal)
2. ✅ Detects what's missing (Python, Git, ROCm) and offers to install it
3. ✅ Clones ComfyUI to `~/ComfyUI` (standard location — `git pull` works)
4. ✅ Creates a separate venv in `~/.venvs/comfyui` (keeps things clean)
5. ✅ Installs PyTorch with ROCm acceleration
6. ✅ Creates **ComfyUI** and **DL Model** desktop shortcuts

> ⏳ Installation takes **10-20 minutes** — PyTorch ROCm is ~6 GB.
> Live log window shows every step. Make a sandwich.

---

## 🎮 Daily Usage

**Start:** Double-click **ComfyUI** on your desktop

**Stop:** Close the browser — ComfyUI shuts down automatically

**Download a model:** Double-click **DL Model** — it's GUI-first

**Web interface:** `http://localhost:8188`

---

## 🗑️ Uninstall

**Copy this 👇 — Paste — Done.**

```bash
cd comfyui-amd-plug-and-play
./uninstall_comfyui.sh
```

Asks if you want to **keep your models** (backed up to `~/comfyui_models_backup`).
Because losing a 30 GB model collection would suck.

---

## 📥 Download a Model

### Option 1 — Desktop shortcut (the easy way)

Double-click **DL Model** → paste URL → pick folder → download.
No terminal, no rename prompts. Your templates will find the file exactly where they expect.

**Supported folders** (yes, all 22 of them):

checkpoints, loras, vae, controlnet, upscale_models, embeddings, text_encoders, clip, clip_vision, diffusion_models, diffusers, unet, audio_encoders, frame_interpolation, gligen, hypernetworks, latent_upscale_models, model_patches, photomaker, style_models, configs, vae_approx

**Example URLs:**

```
# SDXL base
https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# SD 1.5 classic
https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors

# Civitai — copy any model's direct download link
```

### Option 2 — Command line (the old way)

```bash
# SD 1.5 (2 GB, 512×512 images)
wget -c "URL" -O ~/ComfyUI/models/checkpoints/v1-5-pruned-emaonly.safetensors

# SDXL base (7 GB, 1024×1024 images)
wget -c "URL" -O ~/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors

# A LoRA (50-200 MB, styles/characters)
wget -c "URL" -O ~/ComfyUI/models/loras/my_lora.safetensors
```

### VRAM Guide

| Your VRAM | Recommended setup |
|---|---|
| 4 GB | SD 1.5 @ 512×512 |
| 8 GB | SDXL @ 1024×1024 |
| 12 GB | Flux schnell (fast gens) |
| 16 GB | Flux dev (quality gens) |
| 24 GB+ | Flux dev + ControlNet + LoRAs, have fun |

> 💡 Out of memory? Lower the resolution, use a smaller model, or unload other GPU apps. The watchdog helps too — it auto-frees memory after 5 min idle.

---

## 🔧 Useful Commands

**Update ComfyUI (one of the perks of standard layout):**
```bash
cd ~/ComfyUI
source ~/.venvs/comfyui/bin/activate
git pull
pip install -r requirements.txt
deactivate
```

**Install a custom node (example: ComfyUI Manager):**
```bash
cd ~/ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
source ~/.venvs/comfyui/bin/activate
cd ComfyUI-Manager && pip install -r requirements.txt
deactivate
# Restart ComfyUI to load it
```

**Check GPU is actually being used:**
```bash
grep "ROCm\|AMD\|gfx" ~/comfyui.log
# You want to see: pytorch version: X.X.X+rocm7.2
```

**View logs when something breaks:**
```bash
tail -30 ~/comfyui.log
```

See **MEMO.txt** for the full command reference.

---

## 🌐 Where to find models

- 🌐 **Civitai** — https://civitai.com (SD 1.5, SDXL, LoRA, everything)
- 🤗 **HuggingFace** — https://huggingface.co (Flux, SDXL, raw models)
- 📋 **OpenArt Workflows** — https://openart.ai/workflows (ready-made workflows)

---

## 💬 Contributing

Bug? Feature idea? Tip for other users? **Pull requests and issues welcome.**
This isn't a one-person gate-keeping project — it's for the AMD Linux community.

Made by a fellow AMD Linux user who got tired of the setup dance. 🤝

---

## 📄 License

MIT — use it, fork it, break it, make it better.
