# Hyprsimple Personal Configuration Backup

This repository contains a personal backup of Hyprsimple configuration files and custom scripts. It is **not** a fork or replacement for the upstream Hyprsimple installation.

## Relationship to Upstream

- **Upstream repository:** `https://github.com/rizukirr/hyprsimple`
- **Upstream version:** `0.4.11`
- **Upstream commit:** `0bac6fd` (Bump to 0.4.11 #243)
- **Installation path:** `~/.local/share/hyprsimple` (managed by `hyprsimple-update`)

This backup contains configuration overrides and custom scripts, together with third-party material derived from upstream Hyprsimple and the SDDM elarun theme. Upstream-managed files are deliberately excluded because they are delivered by `hyprsimple-update` on every run. Third-party material is not covered by this repository's MIT license; see LICENSE and THIRD-PARTY-NOTICES.md.

## Licensing

This repository is distributed under the MIT License (see `LICENSE`). The MIT
license applies **only to original project content authored by Oreo**. It does
not override third-party licenses or exclusions, and it does not imply that
every file in this repository can be freely relicensed.

Third-party material is documented in `THIRD-PARTY-NOTICES.md`, including:

- Upstream Hyprsimple (`rizukirr/hyprsimple`, v0.4.11): README-declared MIT;
  no upstream LICENSE file or copyright notice was found at the pinned commit.
- SDDM elarun theme: MIT, Copyright (c) 2013 Reza Fatahilah Shah and
  Abdurrahman AVCI; the original MIT header is restored in `sddm/Main.qml`.
- `hypr/themes/japanese-crimson/backgrounds/1-japanese-crimson.jpg`: unknown
  provenance; excluded from the MIT license grant.
- Hyprsimple wallpapers (`1-rainy-workspace.jpg`, `2-neon-cafe-street.jpg`,
  `3-hyprsimple-cafe.jpg`, `sddm/background.jpg`): sourced from upstream;
  artwork rights and the upstream copyright notice remain unverified.

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
| `sddm/Main.qml`, `sddm/theme.conf`, `sddm/background.jpg` | `/usr/share/sddm/themes/hyprsimple/` | SDDM login theme (system-wide) |
| `sddm/99-hyprsimple-theme.conf` | `/etc/sddm.conf.d/` | SDDM theme selection drop-in |

## Personal Customizations

The following files are customizations and overrides. Some may match upstream
defaults byte-for-byte and are not claimed as original project work; see
THIRD-PARTY-NOTICES.md for third-party material.

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
- `hypr/themes/hyprsimple/icon-theme` — `Yaru-purple`
- `hypr/themes/hyprsimple/backgrounds/` — 3 wallpapers sourced from upstream Hyprsimple (not personal artwork; see THIRD-PARTY-NOTICES.md)
- `waybar/config.jsonc` — Custom bar layout with fuzzel launcher
- `waybar/style.css` — Catppuccin Mocha theme
- `ghostty/config` — Font, opacity, keybinds (theme colors rewritten on switch)
- `btop/btop.conf` — Minimal, references generated theme
- `uwsm/env` — Wayland env vars, cursor size
- `starship.toml` — Catppuccin Mocha palette, extensive modules
- `scripts/*` — 8 original project scripts (hypr-clipboard, hypr-clipboard-monitor, hypr-clipboard-paste, hypr-power-menu, search.sh, search_by_keyword.sh, toggle_cpu_mode.sh, sddm-theme-sync.sh). None are derived from upstream Hyprsimple; sddm-theme-sync.sh embeds the third-party SDDM elarun QML template (MIT; see THIRD-PARTY-NOTICES.md).

### SDDM Dynamic Theme

This repository includes a **dynamic SDDM theme** that automatically synchronizes with the active Hyprsimple theme. The implementation is hardened for security and reliability.

**Files:**
- `sddm/Main.qml` — Login screen template (generated at runtime with active theme colors)
- `sddm/theme.conf` — Theme metadata
- `sddm/background.jpg` — Wallpaper placeholder (replaced with active wallpaper at runtime)
- `sddm/99-hyprsimple-theme.conf` — SDDM config drop-in for `/etc/sddm.conf.d/`
- `scripts/sddm-theme-sync.sh` — **Root-owned** synchronization helper (installed to `/usr/local/bin/sddm-theme-sync`)
- `systemd/sddm-theme-sync@.service` — **System-level** boot-time oneshot service (runs before SDDM)
- `systemd/sddm-theme-sync.service` — User-level service for runtime sync (triggered by path unit)
- `systemd/sddm-theme-sync.path` — User-level path unit watching correct source files

**Source vs. runtime:**
- `sddm/Main.qml` is the placeholder-based source template; the helper substitutes active colors and writes the installed runtime `/usr/share/sddm/themes/hyprsimple/Main.qml`.
- `sddm/background.jpg` is a placeholder; the runtime `background.jpg` is generated from the configured wallpaper source.
- `sddm/theme.conf` is the source configuration and should match the output of the helper's `generate_theme_conf()`.
- Installed files under `/usr/share/sddm/themes/hyprsimple/` are overwritten on each sync and must not be edited directly.

**How it works:**
1. Active theme colors are read from `~/.config/quickshell/theme-active.json` (updated by `theme-switcher.sh`)
2. Active wallpaper is read from `~/.cache/current_wallpaper` (updated by `theme-switcher.sh` and `wallpaper-switcher.sh`)
3. **Boot-time:** System service `sddm-theme-sync@<user>.service` runs before `sddm.service`, syncing latest theme
4. **Runtime:** User path unit watches `theme-active.json` and `current_wallpaper*`, triggers user service
5. User service calls root-owned helper `/usr/local/bin/sddm-theme-sync` via passwordless sudo
6. Helper validates all inputs (JSON syntax, color format, wallpaper path/type), generates SDDM theme atomically
7. No manual intervention needed — SDDM updates when you switch themes or wallpapers in Hyprland

**Security hardening:**
- Sync helper owned by `root:root`, mode `0755`, installed at `/usr/local/bin/sddm-theme-sync`
- The NOPASSWD sudoers rule permits passwordless execution of this helper; it is additive and does not restrict an account that already has `(ALL) ALL`
- All user-controlled inputs validated: JSON syntax, `#RRGGBB` color format, wallpaper file type & path
- Wallpaper sources are opened through directory file descriptors with `O_NOFOLLOW`, `O_NONBLOCK`, and `O_DIRECTORY`, preventing symlink and path-traversal attacks and rejecting non-regular files
- Wallpapers are limited to 64 MiB, enforced both on the initial size check and during the streaming copy
- The temporary copy is MIME-validated as `image/jpeg`, `image/png`, or `image/webp` before installation (type validation only, not full image-decoder validation)
- Atomic destination replacement using temporary files + `mv -f` — no partial/corrupted output

**Colors (dynamic, from active theme):**
- Used by the QML template: Background, Surface, Foreground, Accent, Accent Dim, Success, Danger, Info, Muted
- Validated inputs currently unused by the template: Secondary, Warning, Border
- All sourced from `theme-active.json` — no hardcoded values

**Features:**
- Asymmetric layout: a compact glass-style login panel anchored on the left, with the wallpaper visible on the right
- Username/password fields with focus highlighting (accent color)
- Login button uses accent; shutdown, reboot, suspend, and hibernate icons use accent on hover/focus and foreground otherwise
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
- `file` (for wallpaper MIME type validation)
- `python3` (used by the wallpaper synchronization helper)

Standard base-system utilities such as `getent`, `stat`, `mktemp`, `sed`, `chmod`, `mv`, and `cut` are assumed to be available and are not listed individually.

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
   # Back up any existing theme and drop-in before overwriting (timestamped;
   # only items that already exist are backed up)
   BACKUP_TS=$(date +%Y%m%d-%H%M%S)
   THEME_BACKUP="/usr/share/sddm/themes/hyprsimple.bak.$BACKUP_TS"
   CONF_BACKUP="/etc/sddm.conf.d/99-hyprsimple-theme.conf.bak.$BACKUP_TS"
   if [ -d /usr/share/sddm/themes/hyprsimple ]; then
       [ ! -e "$THEME_BACKUP" ] || { echo "Refusing to overwrite $THEME_BACKUP" >&2; exit 1; }
       sudo cp -a /usr/share/sddm/themes/hyprsimple "$THEME_BACKUP"
   fi
   if [ -f /etc/sddm.conf.d/99-hyprsimple-theme.conf ]; then
       [ ! -e "$CONF_BACKUP" ] || { echo "Refusing to overwrite $CONF_BACKUP" >&2; exit 1; }
       sudo cp -a /etc/sddm.conf.d/99-hyprsimple-theme.conf "$CONF_BACKUP"
   fi

   # Install theme files (only the three runtime theme files)
   sudo mkdir -p /usr/share/sddm/themes/hyprsimple
   sudo cp ~/hyprsimple-config-backup/sddm/Main.qml /usr/share/sddm/themes/hyprsimple/
   sudo cp ~/hyprsimple-config-backup/sddm/theme.conf /usr/share/sddm/themes/hyprsimple/
   sudo cp ~/hyprsimple-config-backup/sddm/background.jpg /usr/share/sddm/themes/hyprsimple/
   sudo cp ~/hyprsimple-config-backup/sddm/99-hyprsimple-theme.conf /etc/sddm.conf.d/
   
   # Install root-owned sync helper
   sudo cp ~/hyprsimple-config-backup/scripts/sddm-theme-sync.sh /usr/local/bin/sddm-theme-sync
   sudo chown root:root /usr/local/bin/sddm-theme-sync
   sudo chmod 755 /usr/local/bin/sddm-theme-sync
   
   # Permit passwordless execution of the sync helper (additive; does not reduce existing sudo rights)
   echo "$USER ALL=(ALL) NOPASSWD: /usr/local/bin/sddm-theme-sync" | sudo tee /etc/sudoers.d/sddm-theme-sync

   # Validate the drop-in syntax; this must pass before relying on the rule
   sudo visudo -cf /etc/sudoers.d/sddm-theme-sync
   
   # Install and enable systemd units
   # System-level boot-time service (runs before SDDM)
   sudo cp ~/hyprsimple-config-backup/systemd/sddm-theme-sync@.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable sddm-theme-sync@$USER.service
   
   # User-level runtime sync (watches for theme/wallpaper changes)
   cp ~/hyprsimple-config-backup/systemd/sddm-theme-sync.service ~/.config/systemd/user/
   cp ~/hyprsimple-config-backup/systemd/sddm-theme-sync.path ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now sddm-theme-sync.path
   
   # Enable user lingering so runtime sync works after logout
   loginctl enable-linger $USER
   
   # Initial sync
   sudo /usr/local/bin/sddm-theme-sync
   ```

6. **Reload Hyprland:**
   ```bash
   hyprctl reload
   ```

## Restore Notes

- `hypr/hyprpaper.conf` references `$HOME/.cache/current_wallpaper`. Verify the path matches your `$HOME` after restore. The `theme-switcher.sh` will update this when a theme is applied.
- Do NOT clone this repository into `~/.local/share/hyprsimple`. Keep upstream and personal config separate.
- SDDM theme requires root to install to `/usr/share/sddm/themes/`. The config drop-in goes to `/etc/sddm.conf.d/`.
- A logout or reboot is required to see the new SDDM login screen.
- **Dynamic SDDM theme:** Requires `jq`, `file`, and `python3` packages. The helper is installed as `root:root`, mode `0755`, at `/usr/local/bin/sddm-theme-sync`. The NOPASSWD rule permits passwordless execution of this helper; it is additive and does not restrict an account that already has `(ALL) ALL`. Wallpapers over 64 MiB, symlinks, and non-regular files are rejected, and the temporary copy is MIME-validated before installation.
- System-level boot service `sddm-theme-sync@<user>.service` runs before `sddm.service` — ensures first login screen uses latest theme.
- User-level path unit watches `~/.config/quickshell/theme-active.json` and `~/.cache/current_wallpaper*` — requires `loginctl enable-linger <user>` for post-logout sync.
- The generated `Main.qml` in `/usr/share/sddm/themes/hyprsimple/` is overwritten on every theme/wallpaper change — do not edit it directly.

### SDDM Rollback

The installation step creates timestamped backups only for items that already existed:

```
/usr/share/sddm/themes/hyprsimple.bak.YYYYMMDD-HHMMSS
/etc/sddm.conf.d/99-hyprsimple-theme.conf.bak.YYYYMMDD-HHMMSS
```

List the available backups and choose the timestamp to restore:

```bash
ls -d /usr/share/sddm/themes/hyprsimple.bak.* /etc/sddm.conf.d/99-hyprsimple-theme.conf.bak.* 2>/dev/null
```

Before restoring, record the enabled/active state of the user path unit and the boot-time instance so it can be restored deliberately later:

```bash
UNIT_STATE="$HOME/.local/state/sddm-theme-sync-units.$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$HOME/.local/state"
{
    systemctl --user show -p Id -p UnitFileState -p ActiveState sddm-theme-sync.path
    systemctl show -p Id -p UnitFileState -p ActiveState "sddm-theme-sync@$USER.service"
} > "$UNIT_STATE"
cat "$UNIT_STATE"
```

Then stop the user units and disable the boot-time instance; otherwise a theme or wallpaper change can re-sync and overwrite the restored files:

```bash
systemctl --user stop sddm-theme-sync.path sddm-theme-sync.service
sudo systemctl disable --now "sddm-theme-sync@$USER.service"
```

`sddm-theme-sync.service` is a oneshot triggered by the path unit, and the boot-time instance is also oneshot. Do not start either oneshot service merely to restore an `active` reading; that would run another synchronization immediately. Stopping the path unit does not change whether it is enabled, so start it again only if it was active before. The boot-time instance was disabled by the rollback; re-enable it only if the saved state was `enabled`.

Restore only the items whose backups exist, using the chosen timestamp:

```bash
BACKUP_TS=YYYYMMDD-HHMMSS

if [ -d "/usr/share/sddm/themes/hyprsimple.bak.$BACKUP_TS" ]; then
    if [ -e /usr/share/sddm/themes/hyprsimple ]; then
        sudo mv /usr/share/sddm/themes/hyprsimple "/usr/share/sddm/themes/hyprsimple.replaced.$BACKUP_TS"
    fi
    sudo cp -a "/usr/share/sddm/themes/hyprsimple.bak.$BACKUP_TS" /usr/share/sddm/themes/hyprsimple
fi

if [ -f "/etc/sddm.conf.d/99-hyprsimple-theme.conf.bak.$BACKUP_TS" ]; then
    sudo cp -a "/etc/sddm.conf.d/99-hyprsimple-theme.conf.bak.$BACKUP_TS" /etc/sddm.conf.d/99-hyprsimple-theme.conf
fi
```

After verifying the rollback, use the saved state file to restore only the states that were previously present:

```bash
# Example: run each line only if the saved state matches.
systemctl --user start sddm-theme-sync.path             # saved ActiveState=active
sudo systemctl enable "sddm-theme-sync@$USER.service"   # saved UnitFileState=enabled
```

If the saved `ActiveState` was `inactive`, do not start the path unit. If the saved `UnitFileState` was anything other than `enabled` (for example `disabled` or `static`), do not enable the boot-time instance. Keeping synchronization disabled is an intentional option if the rollback was needed because sync was overwriting files or failing; re-enable only after the cause is fixed.

- If a backup does not exist, that item did not exist before installation. For the theme directory, remove only `/usr/share/sddm/themes/hyprsimple` if you want to undo the installation. For the drop-in, remove only `/etc/sddm.conf.d/99-hyprsimple-theme.conf`. Do not delete other files or drop-ins from `/etc/sddm.conf.d/`.
- The rollback `mv` preserves the replaced theme directory as `hyprsimple.replaced.<timestamp>` instead of deleting it; remove it manually only after confirming the rollback is correct.
- Recovery commands may require a TTY or another safe administrative environment (for example, a virtual console or an SSH session). Do not restart SDDM from an active graphical session as a casual recovery step; the restored theme takes effect on the next normal SDDM start or reboot.
- Keep the saved unit-state file until the rollback is verified, then restore only the previously recorded states.

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