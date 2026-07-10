# mpv-settings

Personal Windows mpv configuration focused on high-quality anime playback, uosc UI, shader management, rounded CJK subtitles, and clean borderless player styling.

## Features

- uosc-based UI, built-in mpv OSC disabled
- Borderless Windows player window with uosc in-player top bar
- Vulkan rendering pipeline
- NVIDIA NVDEC copy-back hardware decoding
- Natural default upscaler: FSRCNNX x2 8-channel
- Right-click uosc menu with categorized shader management
- Toggleable shader building blocks for FSRCNNX and Anime4K
- Neo Glass style uosc layout
- Rounded CJK subtitle setup for Simplified Chinese, Traditional Chinese, and Japanese
- Custom speed button that opens a preset speed menu with top-left speed OSD
- Slim left-side volume slider

## Layout

Current uosc bottom bar:

```text
Left:  Previous  Play/Pause  Next  Speed
Right: Subtitles  Audio tracks  Video tracks

Slim volume slider on the left edge of the player window.
```

Right click opens the uosc menu.

## Install

Clone this repository, then run PowerShell:

```powershell
.\install.ps1
```

This copies the repo contents to:

```text
%APPDATA%\mpv
```

Back up your existing `%APPDATA%\mpv` first if needed.

## Fonts

Large CJK fonts are intentionally not committed to keep the repository small.

Recommended rounded CJK subtitle font:

- Resource Han Rounded / 源柔黑体
- GitHub: https://github.com/CyanoHao/Resource-Han-Rounded
- Release used locally: `v0.990`, `RHR-TTF-0.990.7z`

Install these files into `%APPDATA%\mpv\fonts` for the configured subtitle fonts:

```text
ResourceHanRoundedSC-Regular.ttf
ResourceHanRoundedSC-Bold.ttf
ResourceHanRoundedTC-Regular.ttf
ResourceHanRoundedTC-Bold.ttf
ResourceHanRoundedJ-Regular.ttf
ResourceHanRoundedJ-Bold.ttf
```

If these fonts are not installed, change `sub-font` in `mpv.conf` back to a font you have, e.g.:

```conf
sub-font='Noto Sans CJK SC'
```

## Shader menu

Right click → `Shaders`:

- Current / Reset
- Presets
- Natural scaler
- Protect / Prepare
- Restore detail
- Soft restore
- Upscale
- Upscale + denoise
- Deblur / Denoise / Lines

Individual shader entries toggle on/off, allowing custom combinations.

## Important paths

```text
mpv.conf
input.conf
script-opts/uosc.conf
scripts/neoglass-speed.lua
scripts/neoglass-shaders.lua
shaders/
```

## Notes

This repo is tailored for Windows 11 and a high-end GPU setup. It should still work on other Windows mpv installs, but some options may need adjustment.
