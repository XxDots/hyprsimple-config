# Third-Party Notices

This repository contains third-party material that is **not** covered by this
project's MIT license. Each component below retains its own license and
copyright terms. This repository claims no copyright or ownership over
upstream code or third-party assets.

## 1. Hyprsimple upstream

- Project: `rizukirr/hyprsimple`
  (https://github.com/rizukirr/hyprsimple)
- Pinned version: `0.4.11`
- Pinned commit: `0bac6fd03b738328f11d4b8610b4147d6e7086d5`
- Author shown in commit: `rizuki`
- License: The upstream README declares MIT. No LICENSE file or copyright
  notice was found at the pinned commit; accordingly, no copyright year or
  copyright holder notice is stated here and none is invented.

Upstream-derived files (per the Phase 3J inventory):

- `hypr/themes/hyprsimple/backgrounds/1-rainy-workspace.jpg`
- `hypr/themes/hyprsimple/backgrounds/2-neon-cafe-street.jpg`
- `hypr/themes/hyprsimple/backgrounds/3-hyprsimple-cafe.jpg`
- `sddm/background.jpg`

These files retain the upstream license terms and are **not** independently
relicensed by this repository. Individual artwork rights remain unverified
(see section 4).

## 2. SDDM elarun theme

- Original theme: SDDM elarun
- Copyright (c) 2013 Reza Fatahilah Shah
- Copyright (c) 2013 Abdurrahman AVCI
- License: MIT
- Source: SDDM v0.21.0 `data/themes/elarun/Main.qml`

The original MIT copyright and permission header has been restored at the
beginning of `sddm/Main.qml`, with the Hyprsimple SDDM modifications kept
below it. The embedded QML template in `scripts/sddm-theme-sync.sh` mirrors
`sddm/Main.qml` apart from the intended runtime color substitutions and
template representation, and carries the same notice.

## 3. Japanese Crimson wallpaper

- File: `hypr/themes/japanese-crimson/backgrounds/1-japanese-crimson.jpg`
- Provenance: unknown

This file is **excluded** from the project's MIT license grant. No claim is
made that it is user-created.

## 4. Hyprsimple wallpapers (artwork rights unverified)

- `hypr/themes/hyprsimple/backgrounds/1-rainy-workspace.jpg`
- `hypr/themes/hyprsimple/backgrounds/2-neon-cafe-street.jpg`
- `hypr/themes/hyprsimple/backgrounds/3-hyprsimple-cafe.jpg`
- `sddm/background.jpg`

Sourced from the upstream Hyprsimple repository, whose README declares MIT.
Individual artwork rights and the upstream copyright notice remain unverified.
These images are **not** represented as original project artwork, and this
repository does not definitively claim that the upstream MIT grant covers the
underlying artwork.

## 5. Other files investigated

- `scripts/hypr-clipboard-paste`: Investigated and found to be independently
  implemented. Its "HyDE style" description does not establish copied GPL
  code.
- `waybar/config.jsonc` and `waybar/style.css`: Use Catppuccin palette values
  but were not found to reproduce the official Catppuccin Waybar
  implementation.
