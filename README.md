# Hyprsimple Personal Configuration Backup

This repository contains a personal backup of Hyprsimple configuration files and custom scripts. It is **not** a fork or replacement for the upstream Hyprsimple installation.

## Relationship to Upstream

- **Upstream repository:** `https://github.com/rizukirr/hyprsimple`
- **Upstream version:** `0.4.11`
- **Upstream commit:** `0bac6fd` (Bump to 0.4.11 #243)
- **Installation path:** `~/.local/share/hyprsimple` (managed by `hyprsimple-update`)

This backup contains only user-owned configuration overrides and custom scripts. Upstream-managed files are deliberately excluded because they are delivered by `hyprsimple-update` on every run.

## Directory Mapping

| Repository Path | Original Location | Description |
|-----------------|-------------------|-------------|
| `hypr/` | `~/.config/hypr/` | Core Hyprland configuration |
| `hypr/bindings/` | `~/.config/hypr/bindings/` | Custom keybindings |
| `hypr/themes/hyprsimple/` | `~/.config/hypr/themes/hyprsimple/` | Personal theme (colors, icon theme, wallpapers) |
| `waybar/` | `~/.config/waybar/` | Waybar configuration |
| `ghostty/` | `~/.config/ghostty/` | Ghostty terminal configuration |
| `btop/` | `~/.config/btop/` | btop configuration |
| `uwsm/` | `~/.config/uwsm/` | UWSM session environment |
| `hyprsimple/` | `~/.config/hyprsimple/` | Plugin configuration |
| `scripts/` | `~/.local/bin/` (custom only) | Personal helper scripts |
| `starship.toml` | `~/.config/starship.toml` | Starship prompt configuration |
| `sddm/` | `/usr/share/sddm/themes/hyprsimple/` | SDDM login theme (system-wide) |

## Personal Customizations

The following files are personal overrides that differ from upstream defaults:

- `hypr/hyprland.lua` — Entry point loading upstream + user overrides
- `hypr/vars.lua` — Empty override (uses all upstream defaults)
- `hypr/monitors.lua` — Single monitor auto-configuration
- `hypr/looknfeel.lua` — Empty override
- `hypr/input.lua` — Empty override
- `hypr/windows.lua` — Empty override
- `hypr/autostart.lua` — Empty override
- `hypr/bindings/applications.lua` — 10 custom keybinds (theme switcher, wallpaper, clipboard, color picker, etc.)
- `hypr/hypridle.conf` — Sources 5 upstream idle configs
- `hypr/hyprlock.conf` — Sources theme + upstream lock config
- `hypr/hyprpaper.conf` — Wallpaper path (see Restore Notes)
- `hypr/hyprsunset.conf` — Day profile only
- `hypr/xdph.conf` — Sources upstream xdph config
- `hypr/theme-hyprlock.conf` — Generated lockscreen colors (regenerated on theme switch)
- `hypr/themes/hyprsimple/colors.toml` — Custom Catppuccin-like palette
- `hypr/themes/hyprsimple/icon-theme` — `Papirus-Dark`
- `hypr/themes/hyprsimple/backgrounds/` — 3 personal wallpapers
- `waybar/config.jsonc` — Custom bar layout with fuzzel launcher
- `waybar/style.css` — Catppuccin Mocha theme
- `ghostty/config` — Font, opacity, keybinds (theme colors rewritten on switch)
- `btop/btop.conf` — Minimal, references generated theme
- `uwsm/env` — Wayland env vars, cursor size
- `hyprsimple/plugins.json` — Muslimtify plugin enabled
- `starship.toml` — Catppuccin Mocha palette, extensive modules
- `scripts/*` — 9 custom scripts (clipboard, power menu, waybar toggle, wallpaper, search, CPU toggle)

### SDDM Dynamic Theme

This repository includes a **dynamic SDDM theme** that automatically synchronizes with the active Hyprsimple theme.

**Files:**
- `sddm/Main.qml` — Login screen template (generated at runtime with active theme colors)
- `sddm/theme.conf` — Theme metadata
- `sddm/background.jpg` — Wallpaper placeholder (replaced with active wallpaper at runtime)
- `sddm/99-hyprsimple-theme.conf` — SDDM config drop-in for `/etc/sddm.conf.d/`
- `scripts/sddm-theme-sync.sh` — Synchronization script (reads active colors & wallpaper, generates SDDM theme)
- `systemd/sddm-theme-sync.service` — Systemd service to run sync
- `systemd/sddm-theme-sync.path` — Systemd path unit to auto-trigger sync on theme/wallpaper change

**How it works:**
1. Active theme colors are read from `~/.config/quickshell/theme-active.json` (updated by `theme-switcher.sh`)
2. Active wallpaper is read from `~/.cache/current_wallpaper` (updated by `theme-switcher.sh` and `wallpaper-switcher.sh`)
3. `sddm-theme-sync.sh` generates `/usr/share/sddm/themes/hyprsimple/Main.qml` with the active colors and copies the wallpaper
4. A systemd path unit watches for changes to the colors file and wallpaper, triggering the sync automatically
5. No manual intervention needed — SDDM updates when you switch themes or wallpapers in Hyprland

**Colors (dynamic, from active theme):**
- Background, Surface, Foreground, Accent, Accent Dim, Secondary, Success, Warning, Danger, Muted, Border
- All sourced from `theme-active.json` — no hardcoded values

**Features:**
- Compact centered login card matching reference design
- Username/password fields with focus highlighting (accent color)
- Session selector and keyboard layout dropdown
- Login (accent), Shutdown (danger), Reboot (warning) buttons
- Clock with date at top-right
- Dark semi-transparent overlay on wallpaper for readability
- Lightweight, no Hyprland/Quickshell dependencies
- Works at 1366×768 resolution

## Generated Files (Regenerated on Theme Switch)

These files are **not** in this backup and will be recreated automatically:

- `hypr/theme-active.lua` → symlink to `hypr/themes/hyprsimple/generated/hyprland-colors.lua`
- `hypr/themes/hyprsimple/generated/` — 5 files: `btop.theme`, `ghostty.conf`, `hyprland-colors.lua`, `hyprlock.conf`, `quickshell-colors.json`
- `btop/themes/current.theme` — Generated from active theme
- `~/.config/quickshell/theme-active.json` — Symlink target, same as `quickshell-colors.json`

To regenerate after restore, run:
```bash
theme-switcher.sh hyprsimple
```

## Dependencies

Ensure these are installed before restoring:

- `hyprsimple` (upstream, via `hyprsimple-update`)
- `hyprland`, `hyprpaper`, `hypridle`, `hyprlock`, `hyprsunset`, `xdg-desktop-portal-hyprland`
- `waybar`, `ghostty`, `btop`, `starship`
- `fuzzel`, `cliphist`, `hyprpicker`, `zenity`, `notify-send`
- `nautilus` (file manager), `firefox` (browser)
- `uwsm`, `gsettings`, `hyprctl`
- `Muslimtify` plugin (optional, for prayer times panel)
- `sddm` (for login theme)
- `jq` (for parsing JSON in sync script)

## Restore Procedure

1. **Install upstream Hyprsimple** (if not already present):
   ```bash
   git clone https://github.com/rizukirr/hyprsimple ~/.local/share/hyprsimple
   cd ~/.local/share/hyprsimple && ./install.sh
   ```

2. **Clone this repository** to a temporary location (NOT into `~/.local/share/hyprsimple`):
   ```bash
   git clone https://github.com/XxDots/hyprsimple-config.git ~/hyprsimple-config-backup
   ```

3. **Copy configuration files** to their target locations:
   ```bash
   cp -r ~/hyprsimple-config-backup/hypr/* ~/.config/hypr/
   cp -r ~/hyprsimple-config-backup/waybar/* ~/.config/waybar/
   cp -r ~/hyprsimple-config-backup/ghostty/* ~/.config/ghostty/
   cp -r ~/hyprsimple-config-backup/btop/* ~/.config/btop/
   cp -r ~/hyprsimple-config-backup/uwsm/* ~/.config/uwsm/
   cp -r ~/hyprsimple-config-backup/hyprsimple/* ~/.config/hyprsimple/
   cp ~/hyprsimple-config-backup/starship.toml ~/.config/
   cp ~/hyprsimple-config-backup/scripts/* ~/.local/bin/
   chmod +x ~/.local/bin/hypr-* ~/.local/bin/search* ~/.local/bin/toggle_cpu_mode.sh
   ```

4. **Regenerate theme files:**
   ```bash
   theme-switcher.sh hyprsimple
   ```

5. **Install SDDM dynamic theme** (optional, requires root):
   ```bash
   # Install theme files
   sudo cp -r ~/hyprsimple-config-backup/sddm /usr/share/sddm/themes/hyprsimple
   sudo cp ~/hyprsimple-config-backup/sddm/99-hyprsimple-theme.conf /etc/sddm.conf.d/
   
   # Install sync script
   sudo cp ~/hyprsimple-config-backup/scripts/sddm-theme-sync.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/sddm-theme-sync.sh
   
   # Configure passwordless sudo for sync script (required for auto-sync)
   echo "$USER ALL=(ALL) NOPASSWD: /usr/local/bin/sddm-theme-sync.sh" | sudo tee /etc/sudoers.d/sddm-theme-sync
   
   # Install and enable systemd user units for auto-sync
   cp ~/hyprsimple-config-backup/systemd/sddm-theme-sync.service ~/.config/systemd/user/
   cp ~/hyprsimple-config-backup/systemd/sddm-theme-sync.path ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now sddm-theme-sync.path
   
   # Initial sync
   sudo /usr/local/bin/sddm-theme-sync.sh
   ```

6. **Enable Muslimtify plugin** (if desired):
   ```bash
   hyprsimple-plugin enable muslimtify
   ```

6. **Reload Hyprland:**
   ```bash
   hyprctl reload
   ```

## Restore Notes

- `hypr/hyprpaper.conf` references `/home/oreo/.cache/current_wallpaper`. Verify the path matches your `$HOME` after restore. The `theme-switcher.sh` will update this when a theme is applied.
- The `muslimtify` plugin stores location data in `~/.config/muslimtify/config.json` (excluded from this backup). Reconfigure location after restore if using the plugin.
- Do NOT clone this repository into `~/.local/share/hyprsimple`. Keep upstream and personal config separate.
- SDDM theme requires root to install to `/usr/share/sddm/themes/`. The config drop-in goes to `/etc/sddm.conf.d/`.
- A logout or reboot is required to see the new SDDM login screen.
- **Dynamic SDDM theme:** Requires `jq` package and passwordless sudo for `/usr/local/bin/sddm-theme-sync.sh`. The systemd path unit watches `~/.config/quickshell/theme-active.json` and `~/.cache/current_wallpaper` for changes.
- The generated `Main.qml` in `/usr/share/sddm/themes/hyprsimple/` is overwritten on every theme/wallpaper change — do not edit it directly.

## Updating Hyprsimple

Update upstream independently from this backup:

```bash
hyprsimple-update
```

This pulls the latest upstream release and delivers updated default configs/scripts. Your personal overrides in `~/.config/hypr/` and `~/.config/waybar/` etc. are preserved.

To update this backup repository after making local changes:

```bash
# Copy changes back to the backup repo
cp ~/.config/hypr/hyprland.lua ~/hyprsimple-config-backup/hypr/
# ... repeat for other modified files ...

cd ~/hyprsimple-config-backup
git add -A
git commit -m "Update personal configuration"
git push
```