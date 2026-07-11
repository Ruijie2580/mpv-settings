# mpv-settings

Personal Windows mpv configuration focused on high-quality anime playback, uosc UI, shader management, rounded CJK subtitles, and clean borderless player styling.

## Compatibility

This config is designed for and tested with:

| Component | Version |
|---|---|
| **mpv** | `v0.41.0-244-gaf9c81fa1` (built Mar 2 2026, git master snapshot) |
| **libplacebo** | `v7.360.0` |
| **uosc** | `v5.12.0` (official release) |
| **thumbfast** | latest (included in `scripts/thumbfast.lua`) |
| **GPU** | Vulkan backend (`gpu-api=vulkan`) — required for all GLSL user shaders |

It targets **mpv 0.41+**. Features used that require a recent mpv:

- `gpu-api=vulkan` and `profile=gpu-hq`
- `hwdec=nvdec-copy` (NVIDIA only)
- `video-sync=display-resample`
- `volume-max=150` with uosc side slider nudge disabled (patched `Volume.lua`)
- uosc `open-menu` / `update-menu` / `on_close` callback API
- thumbfast `overlay-add` thumbnails

If you run an older mpv (pre-0.38), some options may error on parse. Update mpv to a recent build.

## Features

- uosc-based UI, built-in mpv OSC disabled
- Borderless Windows player window with uosc in-player top bar
- Vulkan rendering pipeline
- NVIDIA NVDEC copy-back hardware decoding
- Natural default upscaler: FSRCNNX x2 8-channel
- Additional GLSL shaders: RAVU r3/r4, NVScaler/Sharpen, KrigBilateral, CAS, AdaptiveSharpen, SSimSuperRes, SSimDownscaler
- Right-click uosc menu with categorized shader management
- Toggleable shader building blocks for FSRCNNX and Anime4K
- Neo Glass style uosc layout
- Rounded CJK subtitle setup for Simplified Chinese, Traditional Chinese, and Japanese
- Custom speed button that opens a preset speed menu with top-left speed OSD
- Slim right-side volume slider with smooth rounded ends (no sharp nudge)

## Layout

Current uosc bottom bar:

```text
Left:  Previous  Play/Pause  Next  Speed
Right: Subtitles  Audio tracks  Video tracks

Slim volume slider on the right edge of the player window.
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

## Key bindings

All bindings are defined in `input.conf`.

### Playback & UI

| Key | Action |
|---|---|
| `Shift+Enter` | Open uosc Files / Playlist view |
| `Mouse Right` | Open uosc right-click menu |

### Shader presets (quick switch)

| Key | Action |
|---|---|
| `Ctrl+7` | FSRCNNX x2 8-channel (Natural) — default |
| `Ctrl+8` | FSRCNNX x2 16-channel (Quality) |
| `Ctrl+1` | Anime4K Mode A (HQ) |
| `Ctrl+2` | Anime4K Mode B Soft (HQ) |
| `Ctrl+3` | Anime4K Mode C Denoise (HQ) |
| `Ctrl+4` | Anime4K Mode A+A (HQ) |
| `Ctrl+0` | Clear all GLSL shaders |

### Bookmarks

| Key | Action |
|---|---|
| `Alt+b` | Open bookmark menu |
| `b` | Quick-save bookmark at current position |
| `Shift+b` | Quick-load nearest bookmark |

### Subtitle sync

| Key | Action |
|---|---|
| `Alt+s` | Sync subtitles (via `subsync.lua`) |

### Default mpv bindings (not overridden)

These remain mpv/uosc defaults and are not redefined:

| Key | Action |
|---|---|
| `Space` / `p` | Play / Pause |
| `←` / `→` | Seek ±5s |
| `↑` / `↓` | Seek ±60s |
| `Wheel` | Seek (over timeline) / Volume (over side slider) |
| `f` | Toggle fullscreen |
| `m` | Toggle mute |
| `v` | Toggle subtitle visibility |
| `s` | Screenshot |
| `,` / `.` | Frame step back / forward |
| `[` / `]` | Speed down / up |
| `Backspace` | Reset speed to 1x |
| `q` | Quit |
| `Alt+0-3` | Window scale 50% / 100% / 200% / 300% |

### Right-click menu structure

Right-click menu also exposes many actions. The `Shaders` submenu is fully categorized:

- Current / Reset
- Presets
- Upscalers (FSRCNNX, RAVU, NVScaler)
- Chroma / Reconstruction (KrigBilateral, SSimSuperRes)
- Sharpen / Post (AdaptiveSharpen, CAS, NVSharpen)
- Downscalers (SSimDownscaler)
- Anime4K > Protect / Prepare
- Anime4K > Restore detail
- Anime4K > Soft restore
- Anime4K > Upscale
- Anime4K > Upscale + denoise
- Anime4K > Lines / Deblur / Denoise

Other right-click menu entries: Subtitles, Subtitle font (SC/TC/J/fallback), Audio tracks, Stream quality, Playlist, Chapters, Navigation, Utils (aspect ratio, deband toggle, audio devices, screenshot, ...), Quit.

Individual shader entries toggle on/off, allowing custom combinations.

Debanding: mpv has a native `--deband=yes` option; a separate GLSL deband shader is therefore intentionally not bundled here. Toggle built-in debanding via **right-click → Utils → Deband**.

## Important paths

```text
mpv.conf
input.conf
script-opts/uosc.conf
scripts/neoglass-speed.lua
scripts/neoglass-shaders.lua
scripts/thumbfast.lua
scripts/bookmarker.lua
scripts/subsync.lua
scripts/uosc/
shaders/
fonts/
```

## Notes

This repo is tailored for Windows 11 and a high-end GPU setup (Intel Core Ultra 9 185H + RTX 5070 Ti + 32GB RAM, 4K high-refresh display). It should still work on other Windows mpv installs, but some options (hardware decoding, Vulkan) may need adjustment for your hardware.