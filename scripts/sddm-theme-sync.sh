#!/bin/bash

# SDDM Theme Sync - Root Helper
# Reads colors and wallpaper from user's active Hyprsimple theme
# Generates SDDM theme at /usr/share/sddm/themes/hyprsimple/
# This script MUST be owned by root:root and only writable by root

set -euo pipefail

# Configuration
SDDM_THEME_DIR="/usr/share/sddm/themes/hyprsimple"
WALLPAPER_DEST="${SDDM_THEME_DIR}/background.jpg"
MAIN_QML_DEST="${SDDM_THEME_DIR}/Main.qml"
THEME_CONF_DEST="${SDDM_THEME_DIR}/theme.conf"
WALLPAPER_MAX_BYTES=$((64 * 1024 * 1024))

# Colors for output (only to stderr)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { printf "${GREEN}[sddm-sync]${NC} %s\n" "$*" >&2; }
warn() { printf "${YELLOW}[sddm-sync]${NC} %s\n" "$*" >&2; }
err() { printf "${RED}[sddm-sync]${NC} %s\n" "$*" >&2; }

# Validate we are running as root
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    err "This script must run as root"
    exit 1
fi

# Get the target user from SUDO_USER or first argument
TARGET_USER="${SUDO_USER:-${1:-}}"
if [[ -z "${TARGET_USER}" ]]; then
    err "Target user not specified. Use SUDO_USER or pass as first argument."
    exit 1
fi

# Resolve user's home directory
USER_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6)
if [[ -z "${USER_HOME}" || ! -d "${USER_HOME}" ]]; then
    err "Cannot resolve home directory for user: ${TARGET_USER}"
    exit 1
fi

# Source files from user's config
QUICKSHELL_COLORS_FILE="${USER_HOME}/.config/quickshell/theme-active.json"
WALLPAPER_SOURCE="${USER_HOME}/.cache/current_wallpaper"

log "Syncing SDDM theme for user: ${TARGET_USER} (home: ${USER_HOME})"

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    err "jq not found, cannot parse colors.json"
    exit 1
fi

# Validate and read colors JSON
read_colors() {
    local colors_file="$1"

    if [[ ! -f "${colors_file}" ]]; then
        err "Colors file not found: ${colors_file}"
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "${colors_file}" 2>/dev/null; then
        err "Invalid JSON in colors file: ${colors_file}"
        return 1
    fi

    # Read colors with validation
    BACKGROUND=$(jq -r '.background // empty' "${colors_file}")
    SURFACE=$(jq -r '.surface // empty' "${colors_file}")
    FOREGROUND=$(jq -r '.foreground // empty' "${colors_file}")
    ACCENT=$(jq -r '.accent // empty' "${colors_file}")
    ACCENT_DIM=$(jq -r '.accent_dim // empty' "${colors_file}")
    SECONDARY=$(jq -r '.secondary // empty' "${colors_file}")
    SUCCESS=$(jq -r '.success // empty' "${colors_file}")
    WARNING=$(jq -r '.warning // empty' "${colors_file}")
    DANGER=$(jq -r '.danger // empty' "${colors_file}")
    INFO=$(jq -r '.info // empty' "${colors_file}")
    MUTED=$(jq -r '.muted // empty' "${colors_file}")
    BORDER=$(jq -r '.border // empty' "${colors_file}")

    # Validate all colors are present and match hex format
    local all_colors=("${BACKGROUND}" "${SURFACE}" "${FOREGROUND}" "${ACCENT}" "${ACCENT_DIM}" "${SECONDARY}" "${SUCCESS}" "${WARNING}" "${DANGER}" "${INFO}" "${MUTED}" "${BORDER}")
    local color_names=("background" "surface" "foreground" "accent" "accent_dim" "secondary" "success" "warning" "danger" "info" "muted" "border")
    local hex_regex='^#[0-9a-fA-F]{6}$'

    for i in "${!all_colors[@]}"; do
        local color="${all_colors[$i]}"
        local name="${color_names[$i]}"
        if [[ -z "${color}" ]]; then
            err "Missing color: ${name}"
            return 1
        fi
        if [[ ! "${color}" =~ ${hex_regex} ]]; then
            err "Invalid color format for ${name}: ${color} (expected #RRGGBB)"
            return 1
        fi
    done

    return 0
}

# Validate the copied temporary wallpaper file (never the original source path)
validate_wallpaper() {
    local candidate="$1"

    # Must be a regular file, not a symlink or special file.
    if [[ ! -f "${candidate}" || -L "${candidate}" ]]; then
        warn "Wallpaper candidate is not a regular file: ${candidate}"
        return 1
    fi

    local size
    size=$(stat -c %s -- "${candidate}" 2>/dev/null || echo 0)
    if [[ ! "${size}" =~ ^[0-9]+$ || "${size}" -le 0 ]]; then
        warn "Wallpaper candidate is empty or unreadable: ${candidate}"
        return 1
    fi
    if [[ "${size}" -gt "${WALLPAPER_MAX_BYTES}" ]]; then
        warn "Wallpaper candidate exceeds ${WALLPAPER_MAX_BYTES} bytes: ${size}"
        return 1
    fi

    # Check file type is a supported image (validated on the copied bytes).
    local mime_type
    mime_type=$(file --brief --mime-type -- "${candidate}" 2>/dev/null || echo "")
    if [[ ! "${mime_type}" =~ ^image/(jpeg|png|webp)$ ]]; then
        warn "Wallpaper is not a supported image type: ${mime_type}"
        return 1
    fi

    return 0
}

# Sync wallpaper: open the source exactly once (O_NOFOLLOW|O_NONBLOCK), verify it
# with fstat(), stream its bytes into a root-owned temp with a hard size cap, then
# validate and atomically install that temp file.
sync_wallpaper() {
    local tmp_dest=""

    if ! tmp_dest=$(mktemp "${WALLPAPER_DEST}.tmp.XXXXXX"); then
        warn "Cannot create temporary wallpaper file; keeping existing wallpaper"
        return 0
    fi

    # Derive the source components from the configured path, but never open that
    # full pathname. The home directory and .cache are opened as pinned directory
    # descriptors; the wallpaper is opened only relative to the pinned .cache fd.
    local wallpaper_rel="${WALLPAPER_SOURCE#"${USER_HOME}/"}"
    local wallpaper_dir="${wallpaper_rel%/*}"
    local wallpaper_name="${wallpaper_rel##*/}"

    if ! python3 - "${USER_HOME}" "${wallpaper_dir}" "${wallpaper_name}" "${tmp_dest}" "${WALLPAPER_MAX_BYTES}" <<'PYCOPY'
import errno
import os
import stat
import sys

home_path, cache_name, file_name, dst_path = sys.argv[1:5]
max_bytes = int(sys.argv[5])


def fail(message):
    sys.stderr.write("sddm-sync: %s\n" % message)
    try:
        os.unlink(dst_path)
    except OSError:
        pass
    sys.exit(1)


# Mandatory security flags must exist; never fall back to a no-op value.
missing = [name for name in ("O_NOFOLLOW", "O_NONBLOCK", "O_DIRECTORY") if not hasattr(os, name)]
if missing:
    fail("missing required OS flags: %s" % ", ".join(missing))

O_NOFOLLOW = os.O_NOFOLLOW
O_NONBLOCK = os.O_NONBLOCK
O_DIRECTORY = os.O_DIRECTORY

# The source must be exactly one directory component plus one file component.
if (not cache_name or not file_name
        or os.sep in cache_name or os.sep in file_name
        or cache_name in (".", "..") or file_name in (".", "..")):
    fail("invalid wallpaper source layout")

try:
    home_fd = os.open(home_path, os.O_RDONLY | O_DIRECTORY)
except OSError as exc:
    fail("cannot open user home directory: %s" % (exc.strerror or exc))

cache_fd = None
src_fd = None
try:
    try:
        cache_fd = os.open(cache_name, os.O_RDONLY | O_DIRECTORY | O_NOFOLLOW, dir_fd=home_fd)
    except OSError as exc:
        if exc.errno == errno.ELOOP:
            fail("wallpaper cache directory is a symlink")
        fail("cannot open wallpaper cache directory: %s" % (exc.strerror or exc))

    try:
        src_fd = os.open(file_name, os.O_RDONLY | O_NOFOLLOW | O_NONBLOCK, dir_fd=cache_fd)
    except OSError as exc:
        if exc.errno == errno.ELOOP:
            fail("wallpaper source is a symlink")
        fail("cannot open wallpaper source: %s" % (exc.strerror or exc))

    st = os.fstat(src_fd)
    if not stat.S_ISREG(st.st_mode):
        fail("wallpaper source is not a regular file")
    if st.st_size == 0:
        fail("wallpaper source is empty")
    if st.st_size > max_bytes:
        fail("wallpaper source exceeds %d bytes" % max_bytes)

    try:
        dst_fd = os.open(dst_path, os.O_WRONLY | os.O_TRUNC | O_NOFOLLOW)
    except OSError as exc:
        fail("cannot open wallpaper temp file: %s" % (exc.strerror or exc))

    total = 0
    try:
        while True:
            chunk = os.read(src_fd, 65536)
            if not chunk:
                break
            total += len(chunk)
            if total > max_bytes:
                fail("wallpaper grew beyond %d bytes during copy" % max_bytes)
            view = memoryview(chunk)
            while view:
                written = os.write(dst_fd, view)
                if written <= 0:
                    fail("short write while copying wallpaper")
                view = view[written:]
        if total == 0:
            fail("wallpaper source is empty")
        os.fsync(dst_fd)
    finally:
        os.close(dst_fd)
finally:
    if src_fd is not None:
        os.close(src_fd)
    if cache_fd is not None:
        os.close(cache_fd)
    os.close(home_fd)
PYCOPY
    then
        warn "Wallpaper copy failed; keeping existing wallpaper"
        rm -f -- "${tmp_dest}"
        return 0
    fi

    # Validate the copied bytes, not the original pathname.
    if ! validate_wallpaper "${tmp_dest}"; then
        warn "Skipping wallpaper sync (validation failed); keeping existing wallpaper"
        rm -f -- "${tmp_dest}"
        return 0
    fi

    # Prepare final ownership/mode before the atomic replacement.
    if ! chown root:root -- "${tmp_dest}" || ! chmod 0644 -- "${tmp_dest}"; then
        warn "Failed to set wallpaper ownership/permissions; keeping existing wallpaper"
        rm -f -- "${tmp_dest}"
        return 0
    fi

    if mv -f -- "${tmp_dest}" "${WALLPAPER_DEST}"; then
        log "Wallpaper synced to ${WALLPAPER_DEST}"
    else
        warn "Failed to install wallpaper; keeping existing wallpaper"
        rm -f -- "${tmp_dest}"
    fi
}

# Generate theme.conf
generate_theme_conf() {
    local tmp_conf=$(mktemp "${THEME_CONF_DEST}.tmp.XXXXXX")
    cat > "${tmp_conf}" <<'EOF'
[General]
background=background.jpg

[Metadata]
Name=Hyprsimple Dynamic
Version=1.0
Author=Hyprsimple Config
Description=Dynamic SDDM theme matching active Hyprsimple theme
EOF
    chmod 644 "${tmp_conf}"
    mv -f "${tmp_conf}" "${THEME_CONF_DEST}"
    log "Generated theme.conf"
}

# Generate Main.qml with validated colors using atomic write
generate_main_qml() {
    local tmp_qml=$(mktemp "${MAIN_QML_DEST}.tmp.XXXXXX")

    cat > "${tmp_qml}" <<'QMLEOF'
/***************************************************************************
 * SDDM elarun theme
 * Original theme: SDDM elarun
 * Source: SDDM v0.21.0 data/themes/elarun/Main.qml
 *
 * Copyright (c) 2013 Reza Fatahilah Shah
 * Copyright (c) 2013 Abdurrahman AVCI
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ***************************************************************************/

/***************************************************************************
 * Hyprsimple SDDM Dynamic Theme
 * Asymmetric layout: login panel left, wallpaper right
 * Colors and wallpaper synchronized from active Hyprsimple theme
 * DO NOT EDIT - Generated by sddm-theme-sync
 ***************************************************************************/

import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: container
    anchors.fill: parent

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int sessionIndex: 0

    TextConstants { id: textConstants }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            errorMessage.color = @@SUCCESS@@
            errorMessage.text = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            password.text = ""
            errorMessage.color = @@DANGER@@
            errorMessage.text = textConstants.loginFailed
        }
        function onInformationMessage(message) {
            errorMessage.color = @@INFO@@
            errorMessage.text = message
        }
    }

    // Background - full screen wallpaper
    Background {
        anchors.fill: parent
        source: Qt.resolvedUrl(config.background)
        fillMode: Image.PreserveAspectCrop
        onStatusChanged: {
            var defaultBackground = Qt.resolvedUrl(config.defaultBackground)
            if (status == Image.Error && source != defaultBackground) {
                source = defaultBackground
            }
        }
    }

    // Dark overlay for text readability
    Rectangle {
        anchors.fill: parent
        color: @@BACKGROUND@@
        opacity: 0.55
    }

    // Clock at top-right
    Clock {
        id: clock
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 24
        color: @@FOREGROUND@@
        timeFont.family: "JetBrainsMono Nerd Font Mono"
        timeFont.pixelSize: 28
        dateFont.family: "JetBrainsMono Nerd Font Mono"
        dateFont.pixelSize: 12
    }

    // Left login panel (glass: translucent dark fill; no native blur because
    // QtGraphicalEffects is not installed in this Qt/SDDM runtime)
    Rectangle {
        id: loginPanel
        width: Math.min(300, parent.width * 0.25)
        height: mainColumn.implicitHeight + 60
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Math.max(24, parent.width * 0.03)
        radius: 14
        color: "transparent"
        clip: true

        // Translucent glass fill (safe fallback when real blur is unavailable)
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: @@SURFACE@@
            opacity: 0.48
        }

        Column {
            id: mainColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 12

            // Welcome heading
            Text {
                id: welcomeText
                width: parent.width
                color: @@FOREGROUND@@
                text: textConstants.welcomeText.arg(sddm.hostName)
                wrapMode: Text.WordWrap
                font.pixelSize: 20
                font.weight: Font.Medium
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }

            // Date display (below welcome)
            Text {
                id: dateText
                width: parent.width
                color: @@MUTED@@
                text: {
                    var d = new Date();
                    return d.toLocaleDateString(Qt.locale(), { weekday: "long", year: "numeric", month: "long", day: "numeric" });
                }
                font.pixelSize: 13
                horizontalAlignment: Text.AlignLeft
            }

            // Username field
            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: textConstants.userName
                    color: @@FOREGROUND@@
                    font.bold: true
                    font.pixelSize: 13
                }
                TextBox {
                    id: name
                    width: parent.width; height: 34
                    text: userModel.lastUser
                    font.pixelSize: 15
                    textColor: @@FOREGROUND@@
                    color: @@SURFACE@@
                    borderColor: @@MUTED@@
                    focusColor: @@ACCENT@@
                    hoverColor: @@ACCENT_DIM@@
                    radius: 12
                    KeyNavigation.tab: password

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(name.text, password.text, sessionIndex)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Backtab) {
                            if (hibernateButton.visible) hibernateButton.forceActiveFocus();
                            else if (suspendButton.visible) suspendButton.forceActiveFocus();
                            else rebootButton.forceActiveFocus();
                            event.accepted = true
                        }
                    }
                }
            }

            // Password field
            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: textConstants.password
                    color: @@FOREGROUND@@
                    font.bold: true
                    font.pixelSize: 13
                }
                PasswordBox {
                    id: password
                    width: parent.width; height: 34
                    font.pixelSize: 15
                    textColor: @@FOREGROUND@@
                    color: @@SURFACE@@
                    borderColor: @@MUTED@@
                    focusColor: @@ACCENT@@
                    hoverColor: @@ACCENT_DIM@@
                    radius: 12
                    KeyNavigation.backtab: name; KeyNavigation.tab: loginButton

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(name.text, password.text, sessionIndex)
                            event.accepted = true
                        }
                    }
                }
            }

            // Error/info message area
            Text {
                id: errorMessage
                width: parent.width
                text: textConstants.prompt
                color: @@MUTED@@
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            // Login button
            Button {
                id: loginButton
                width: parent.width
                height: 34
                text: textConstants.login
                font.pixelSize: 14
                font.bold: true
                textColor: @@FOREGROUND@@
                color: @@ACCENT@@
                activeColor: @@ACCENT_DIM@@
                pressedColor: @@SURFACE@@
                borderColor: @@ACCENT@@
                radius: 10
                onClicked: sddm.login(name.text, password.text, sessionIndex)
                KeyNavigation.backtab: password; KeyNavigation.tab: shutdownButton
            }

            // System controls row - icon buttons (30x30 clickable, ~17px icons)
            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                // Shutdown
                Item {
                    id: shutdownButton
                    width: 30
                    height: 30

                    Text {
                        id: shutdownIcon
                        anchors.centerIn: parent
                        font.pixelSize: 23
                        font.family: "JetBrainsMono Nerd Font Mono"
                        color: (shutdownMouse.containsMouse || shutdownButton.activeFocus) ? @@ACCENT@@ : @@FOREGROUND@@
                        text: "⏻"
                    }

                    // Tooltip: Shutdown
                    Text {
                        id: shutdownTip
                        text: textConstants.shutdown
                        visible: shutdownMouse.containsMouse || shutdownButton.activeFocus
                        anchors.bottom: parent.top
                        anchors.bottomMargin: -6
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: @@FOREGROUND@@
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: shutdownMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: sddm.powerOff()
                    }

                    KeyNavigation.tab: rebootButton; KeyNavigation.backtab: loginButton
                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                            sddm.powerOff()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Tab) {
                            if (rebootButton.visible) rebootButton.forceActiveFocus();
                            else if (suspendButton.visible) suspendButton.forceActiveFocus();
                            else if (hibernateButton.visible) hibernateButton.forceActiveFocus();
                            else name.forceActiveFocus();
                            event.accepted = true
                        } else if (event.key === Qt.Key_Backtab) {
                            loginButton.forceActiveFocus();
                            event.accepted = true
                        }
                    }
                }

                // Reboot
                Item {
                    id: rebootButton
                    width: 30
                    height: 30

                    Text {
                        id: rebootIcon
                        anchors.centerIn: parent
                        font.pixelSize: 23
                        font.family: "JetBrainsMono Nerd Font Mono"
                        color: (rebootMouse.containsMouse || rebootButton.activeFocus) ? @@ACCENT@@ : @@FOREGROUND@@
                        text: "↻"
                    }

                    // Tooltip: Reboot
                    Text {
                        id: rebootTip
                        text: textConstants.reboot
                        visible: rebootMouse.containsMouse || rebootButton.activeFocus
                        anchors.bottom: parent.top
                        anchors.bottomMargin: -6
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: @@FOREGROUND@@
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: sddm.reboot()
                    }

                    KeyNavigation.tab: suspendButton; KeyNavigation.backtab: shutdownButton
                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                            sddm.reboot()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Tab) {
                            if (suspendButton.visible) suspendButton.forceActiveFocus();
                            else if (hibernateButton.visible) hibernateButton.forceActiveFocus();
                            else name.forceActiveFocus();
                            event.accepted = true
                        } else if (event.key === Qt.Key_Backtab) {
                            shutdownButton.forceActiveFocus();
                            event.accepted = true
                        }
                    }
                }

                // Suspend
                Item {
                    id: suspendButton
                    width: 30
                    height: 30
                    visible: sddm.canSuspend

                    Text {
                        id: suspendIcon
                        anchors.centerIn: parent
                        font.pixelSize: 23
                        font.family: "JetBrainsMono Nerd Font Mono"
                        color: (suspendMouse.containsMouse || suspendButton.activeFocus) ? @@ACCENT@@ : @@FOREGROUND@@
                        text: "☾"
                    }

                    // Tooltip: Suspend
                    Text {
                        id: suspendTip
                        text: textConstants.suspend
                        visible: suspendMouse.containsMouse || suspendButton.activeFocus
                        anchors.bottom: parent.top
                        anchors.bottomMargin: -6
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: @@FOREGROUND@@
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: suspendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: sddm.suspend()
                    }

                    KeyNavigation.tab: hibernateButton; KeyNavigation.backtab: rebootButton
                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                            sddm.suspend()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Tab) {
                            if (hibernateButton.visible) hibernateButton.forceActiveFocus();
                            else name.forceActiveFocus();
                            event.accepted = true
                        } else if (event.key === Qt.Key_Backtab) {
                            rebootButton.forceActiveFocus();
                            event.accepted = true
                        }
                    }
                }

                // Hibernate
                Item {
                    id: hibernateButton
                    width: 30
                    height: 30
                    visible: sddm.canHibernate

                    Text {
                        id: hibernateIcon
                        anchors.centerIn: parent
                        font.pixelSize: 23
                        font.family: "JetBrainsMono Nerd Font Mono"
                        color: (hibernateMouse.containsMouse || hibernateButton.activeFocus) ? @@ACCENT@@ : @@FOREGROUND@@
                        text: "❄"
                    }

                    // Tooltip: Hibernate
                    Text {
                        id: hibernateTip
                        text: textConstants.hibernate
                        visible: hibernateMouse.containsMouse || hibernateButton.activeFocus
                        anchors.bottom: parent.top
                        anchors.bottomMargin: -6
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: @@FOREGROUND@@
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: hibernateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: sddm.hibernate()
                    }

                    KeyNavigation.tab: name; KeyNavigation.backtab: suspendButton
                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                            sddm.hibernate()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Tab) {
                            name.forceActiveFocus();
                            event.accepted = true
                        } else if (event.key === Qt.Key_Backtab) {
                            if (suspendButton.visible) suspendButton.forceActiveFocus();
                            else rebootButton.forceActiveFocus();
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (name.text == "")
            name.focus = true
        else
            password.focus = true
    }
}
QMLEOF

    # Substitute color placeholders with validated values
    sed -i \
        -e "s/@@BACKGROUND@@/\"${BACKGROUND}\"/g" \
        -e "s/@@SURFACE@@/\"${SURFACE}\"/g" \
        -e "s/@@FOREGROUND@@/\"${FOREGROUND}\"/g" \
        -e "s/@@ACCENT@@/\"${ACCENT}\"/g" \
        -e "s/@@ACCENT_DIM@@/\"${ACCENT_DIM}\"/g" \
        -e "s/@@SECONDARY@@/\"${SECONDARY}\"/g" \
        -e "s/@@SUCCESS@@/\"${SUCCESS}\"/g" \
        -e "s/@@WARNING@@/\"${WARNING}\"/g" \
        -e "s/@@DANGER@@/\"${DANGER}\"/g" \
        -e "s/@@INFO@@/\"${INFO}\"/g" \
        -e "s/@@MUTED@@/\"${MUTED}\"/g" \
        -e "s/@@BORDER@@/\"${BORDER}\"/g" \
        "${tmp_qml}"

    # Validate QML syntax by checking no placeholders remain
    if grep -q '@@' "${tmp_qml}"; then
        err "Unreplaced placeholders found in generated QML"
        rm -f "${tmp_qml}"
        return 1
    fi

    chmod 644 "${tmp_qml}"
    mv -f "${tmp_qml}" "${MAIN_QML_DEST}"
    log "Generated Main.qml with dynamic colors"
}

# Main execution
main() {
    log "Starting SDDM theme sync for user: ${TARGET_USER}"

    # Ensure SDDM theme directory exists
    mkdir -p "${SDDM_THEME_DIR}"
    chmod 755 "${SDDM_THEME_DIR}"

    # Read and validate colors
    if ! read_colors "${QUICKSHELL_COLORS_FILE}"; then
        err "Failed to read/validate colors from ${QUICKSHELL_COLORS_FILE}"
        exit 1
    fi
    log "Colors loaded and validated from ${QUICKSHELL_COLORS_FILE}"

    # Sync wallpaper
    sync_wallpaper

    # Generate configs
    generate_theme_conf
    generate_main_qml

    log "SDDM theme sync complete"
}

main "$@"