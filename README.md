# 🎨 ComfyUI — AMD Plug & Play

> **No terminal gymnastics. No dependency hell. Just vibes and Stable Diffusion on AMD.**

Tired of spending your Saturday wrestling with PyTorch wheels, ROCm versions, venv juggling and 47 Stack Overflow tabs about "RuntimeError: CUDA error" on a machine that has no CUDA?
Yeah, same. That's why this exists.

**One click. Coffee-break install. ComfyUI working on your AMD GPU.**

---

## 🎉 What's new — v2.0.0

- 🔥 **ROCm 7.2.2** — latest production stable, AMD official repos, RDNA4 ready
- 📁 **Custom install location** — pick where things live, with a clickable symlink to your models for easy file-manager access
- 🪟 **WebApp pattern** — ComfyUI now opens in its own dedicated window (like Mint's WebApp Manager apps), zero pollution of your personal Firefox profile
- 🎮 **Auto GPU split** — APU + dGPU setups (most modern Ryzens) are auto-configured to dedicate the dGPU to AI, freeing the iGPU for your desktop
- 🗂️ **Manage your models from the file manager** — drag-and-drop `.safetensors` files into checkpoints/, vae/, lora/ folders directly from Thunar/Nautilus
- 🚀 **Launcher renamed** — `comfyui.sh` → `comfyui-launcher.sh` for clarity
- ⚙️ **Self-detecting launcher** — works with default OR custom install paths automatically
- 🛡️ **Smart repair** — broken something? Re-launch the icon, the script detects what's missing and offers a fix
- 🔧 **Hardened install** — verifies source files exist before copying, no silent failures

> ⚠️ **Breaking change from v1.x:** the launcher script was renamed. Existing users will be silently migrated on next launch — no manual action needed.

---

## ✨ What you get

- 🖥️ **Desktop shortcut** — double-click. That's the whole workflow.
- 🎨 **ComfyUI** — official repo, latest version, with full AMD ROCm acceleration
- 🐍 **Isolated Python venv** — PyTorch ROCm 7.2 (latest), no system pollution
- 🪟 **Dedicated app window** — separate from your personal Firefox, won't mess with your tabs
- 🤖 **EZMoDL companion** — easy model downloader (Hugging Face + Civitai), bonus shortcut on your desktop
- 🔒 **Fully offline** — your prompts and generations don't leave your GPU
- ⚡ **On-demand** — services start when you click, stop when you close the browser
- 💾 **VRAM watchdog** — frees GPU memory when you stop generating
- 🔋 **Power efficient** — nothing runs at boot, no wasted wattage

---

## 🖥️ Requirements

| Component | Requirement |
|---|---|
| **OS** | Ubuntu 24.04 LTS **or** Linux Mint 22.x (XFCE/Cinnamon) |
| **GPU** | AMD with ROCm support (RX 6000 series and newer) |
| **VRAM** | 8 GB minimum (12+ GB recommended for SDXL/Flux) |
| **RAM** | 16 GB minimum |
| **Storage** | 30 GB free (ROCm + ComfyUI + venv + models) |
| **Internet** | For initial setup + model downloads |

> ⚠️ **RDNA4 gang (RX 9070 / 9070 XT):** `HSA_OVERRIDE_GFX_VERSION=12.0.1` is wired up. You're welcome.

> 💡 **APU + dGPU users (most Ryzen 7000+/8000+/9000+):** the launcher detects your dual-GPU setup and tells ComfyUI to use only the dedicated GPU. Frees the iGPU for your desktop, no session crash on heavy generations.

---

## 📦 Installation

**Copy 👇 — Paste — Grab a coffee ☕**

```bash
git clone https://github.com/miradorventus/comfyui-amd-plug-and-play.git
cd comfyui-amd-plug-and-play
chmod +x install_comfyui.sh
./install_comfyui.sh
```

The installer is **GUI all the way** — no scary terminal stuff:

### Step 0 — Welcome
Adaptive popup that scans your system and tells you exactly what's there, what's missing, and how big the download will be.

### Step 0.5 — Install location *(new in v2.0.0)*
Pick where to install:
- ✅ **Default** — `~/.comfyui/` (hidden, standard Linux convention)
- 📁 **Custom location** — pick your parent folder (e.g., `~/AI-Tools/`), the installer creates `<your-folder>/comfyui/` for scripts and `<your-folder>/comfy-models` as a clickable shortcut to `~/ComfyUI/models/`
- ← **Back** — change your mind

### Step 1 — Install
Watching paint dry has never been more entertaining: rotating tips while ROCm + Python venv + ComfyUI + PyTorch all install. Sit back.

If ROCm needs to be installed, you'll be asked to reboot at the end. Standard.

### Step 2 — Done
"Launch now?" — click and start generating images.

---

## 🎮 Daily Usage

**Start:** Double-click **ComfyUI** on your desktop

**Stop:** Close the browser window — services shut down, GPU freed

**Web interface:** `http://127.0.0.1:8188`

**Want a model?** Double-click **EZMoDL** (the green crystal icon) and paste a Hugging Face or Civitai URL. Done.

**Already running?** Click the ComfyUI icon again — it tells you to look at the existing window.

---

## 📁 Manage Your Models from the File Manager

If you chose a custom install location, you have a clickable `comfy-models` shortcut next to your `comfyui/` folder. Open it in Thunar / Nautilus / Caja, and you can:

- 📥 **Drag-and-drop** `.safetensors` checkpoints into `checkpoints/`
- 🎨 **Drop LoRAs** into `lora/`
- 🖼️ **Drop VAEs** into `vae/`
- 🎮 **Drop ControlNet** into `controlnet/`
- 🗑️ **Delete** anything without sudo gymnastics
- 📂 **Browse** what's actually on disk

The shortcut is a symlink to `~/ComfyUI/models/`. The 22 standard model sub-folders are pre-created for you.

---

## 🤖 EZMoDL — The Easy Model Downloader

ComfyUI on its own asks you to find URLs, manually drop them in the right folder. EZMoDL automates this:

1. Double-click the **EZMoDL** icon
2. Paste any **Hugging Face** or **Civitai** URL
3. EZMoDL detects what kind of model it is (checkpoint, LoRA, VAE, etc.) and drops it in the right folder automatically

```bash
# Or run it from terminal if you prefer
~/.comfyui/ezmodl.sh
```

---

## 🛠️ Smart Repair

Things break sometimes. Updates conflict. Files get deleted.

If something's wrong with your install, **just relaunch the ComfyUI icon**. The launcher silently checks all components (repo, venv, scripts, models folder) and pops up a clear list of what's missing, with a **"Repair now"** button that runs the installer to fix only what's broken. Your generations and models stay safe.

---

## 🗑️ Uninstall

**Copy 👇 — Paste — Done.**

```bash
cd comfyui-amd-plug-and-play
./uninstall_comfyui.sh
```

- ✅ Removes ComfyUI repo, venv, launch scripts, desktop shortcuts
- 💾 **Keeps your models** in `~/ComfyUI/models/` (delete manually if you want the space back)
- 💾 **Keeps your output images** in `~/ComfyUI/output/`

---

## 🔧 Useful Commands

**Check GPU usage during a generation:**
```bash
watch -n 1 rocm-smi --showuse --showtemp --showmeminfo vram
```

**View ComfyUI log:**
```bash
# Default location
cat ~/.comfyui/comfyui.log

# Or your custom location
cat ~/AI-Tools/comfyui/comfyui.log
```

**Restart manually:**
```bash
~/.comfyui/stopcomfy.sh
~/.comfyui/comfyui-launcher.sh
```

**Multi-GPU? Check which GPU is in use:**
```bash
echo $HIP_VISIBLE_DEVICES
# 0 = first dedicated GPU (correct for APU+dGPU setups)
```

---

## 🙏 Sources Used (all official)

| Component | Source |
|---|---|
| ComfyUI | https://github.com/comfyanonymous/ComfyUI |
| PyTorch ROCm | https://download.pytorch.org/whl/rocm7.2 |
| ROCm 7.2.2 | https://repo.radeon.com (AMD official) |
| Python | Ubuntu/Mint apt repos |

No PPA. No fork. No mirror. Just trust + officialness.

---

## 💬 Contributing

Found a bug? Tested on a setup we don't list? Want a feature?
**Issues and PRs welcome** — this is a community thing.

Made by a fellow AMD Linux user who got tired of "you need NVIDIA for AI" gatekeeping. For everyone else who got tired too. 🤝

---

## 📄 License

MIT — use it, fork it, break it, make it better.
