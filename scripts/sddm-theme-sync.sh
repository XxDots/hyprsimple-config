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
    MUTED=$(jq -r '.muted // empty' "${colors_file}")
    BORDER=$(jq -r '.border // empty' "${colors_file}")

    # Validate all colors are present and match hex format
    local all_colors=("${BACKGROUND}" "${SURFACE}" "${FOREGROUND}" "${ACCENT}" "${ACCENT_DIM}" "${SECONDARY}" "${SUCCESS}" "${WARNING}" "${DANGER}" "${MUTED}" "${BORDER}")
    local color_names=("background" "surface" "foreground" "accent" "accent_dim" "secondary" "success" "warning" "danger" "muted" "border")
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

# Validate wallpaper source
validate_wallpaper() {
    local source="$1"

    if [[ ! -f "${source}" ]]; then
        warn "Wallpaper source not found: ${source}"
        return 1
    fi

    # Check it's a regular file (not symlink, not device, etc.)
    if [[ ! -f "${source}" || -L "${source}" ]]; then
        warn "Wallpaper source is not a regular file or is a symlink: ${source}"
        return 1
    fi

    # Check it's under user's cache directory (prevent path traversal)
    local real_source=$(realpath -e "${source}" 2>/dev/null || echo "")
    local real_cache=$(realpath -e "${USER_HOME}/.cache" 2>/dev/null || echo "")
    if [[ -z "${real_source}" || -z "${real_cache}" ]]; then
        warn "Cannot resolve real paths for wallpaper validation"
        return 1
    fi
    if [[ "${real_source}" != "${real_cache}"* ]]; then
        warn "Wallpaper source outside allowed directory: ${real_source}"
        return 1
    fi

    # Check file type is an image
    local mime_type=$(file --brief --mime-type "${source}" 2>/dev/null || echo "")
    if [[ ! "${mime_type}" =~ ^image/(jpeg|png|webp) ]]; then
        warn "Wallpaper is not a supported image type: ${mime_type}"
        return 1
    fi

    return 0
}

# Sync wallpaper using atomic write
sync_wallpaper() {
    if validate_wallpaper "${WALLPAPER_SOURCE}"; then
        local tmp_dest=$(mktemp "${WALLPAPER_DEST}.tmp.XXXXXX")
        cp "${WALLPAPER_SOURCE}" "${tmp_dest}"
        chmod 644 "${tmp_dest}"
        mv -f "${tmp_dest}" "${WALLPAPER_DEST}"
        log "Wallpaper synced to ${WALLPAPER_DEST}"
    else
        warn "Skipping wallpaper sync (validation failed)"
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
 * Hyprsimple SDDM Dynamic Theme
 * Colors and wallpaper synchronized from active Hyprsimple theme
 * DO NOT EDIT - Generated by sddm-theme-sync
 ***************************************************************************/

import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: container
    width: 640
    height: 480

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int sessionIndex: session.index

    TextConstants { id: textConstants }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            errorMessage.color = @@ACCENT@@
            errorMessage.text = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            password.text = ""
            errorMessage.color = @@DANGER@@
            errorMessage.text = textConstants.loginFailed
        }
        function onInformationMessage(message) {
            errorMessage.color = @@DANGER@@
            errorMessage.text = message
        }
    }

    // Background
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

    // Dark overlay for better text readability
    Rectangle {
        anchors.fill: parent
        color: @@BACKGROUND@@
        opacity: 0.6
    }

    // Main login panel
    Rectangle {
        id: loginPanel
        anchors.centerIn: parent
        width: Math.max(360, mainColumn.implicitWidth + 60)
        height: mainColumn.implicitHeight + 60
        radius: 12
        color: @@SURFACE@@
        border.color: @@ACCENT@@
        border.width: 2

        Column {
            id: mainColumn
            anchors.centerIn: parent
            spacing: 16

            // Welcome text
            Text {
                id: welcomeText
                anchors.horizontalCenter: parent.horizontalCenter
                color: @@FOREGROUND@@
                text: textConstants.welcomeText.arg(sddm.hostName)
                wrapMode: Text.WordWrap
                font.pixelSize: 22
                font.weight: Font.Medium
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
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
                    width: parent.width; height: 38
                    text: userModel.lastUser
                    font.pixelSize: 15
                    textColor: @@FOREGROUND@@
                    color: @@SURFACE@@
                    borderColor: @@MUTED@@
                    focusColor: @@ACCENT@@
                    hoverColor: @@ACCENT_DIM@@
                    radius: 6
                    KeyNavigation.backtab: rebootButton; KeyNavigation.tab: password

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(name.text, password.text, sessionIndex)
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
                    width: parent.width; height: 38
                    font.pixelSize: 15
                    textColor: @@FOREGROUND@@
                    color: @@SURFACE@@
                    borderColor: @@MUTED@@
                    focusColor: @@ACCENT@@
                    hoverColor: @@ACCENT_DIM@@
                    radius: 6
                    KeyNavigation.backtab: name; KeyNavigation.tab: session

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(name.text, password.text, sessionIndex)
                            event.accepted = true
                        }
                    }
                }
            }

            // Session selector
            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: textConstants.session
                    color: @@FOREGROUND@@
                    font.bold: true
                    font.pixelSize: 13
                }

                ComboBox {
                    id: session
                    width: parent.width; height: 38
                    font.pixelSize: 15
                    color: @@SURFACE@@
                    borderColor: @@MUTED@@
                    focusColor: @@ACCENT@@
                    hoverColor: @@ACCENT_DIM@@
                    textColor: @@FOREGROUND@@
                    menuColor: @@SURFACE@@
                    arrowColor: @@ACCENT@@
                    KeyNavigation.backtab: password; KeyNavigation.tab: layoutBox
                }
            }

            // Keyboard layout (only show if multiple)
            Column {
                width: parent.width
                spacing: 6
                visible: keyboard.enabled && keyboard.layouts.length > 0

                Text {
                    text: textConstants.layout
                    color: @@FOREGROUND@@
                    font.bold: true
                    font.pixelSize: 13
                }

                LayoutBox {
                    id: layoutBox
                    width: parent.width; height: 38
                    font.pixelSize: 15
                    color: @@FOREGROUND@@
                    KeyNavigation.backtab: session; KeyNavigation.tab: loginButton
                }
            }

            // Error/info message
            Text {
                id: errorMessage
                anchors.horizontalCenter: parent.horizontalCenter
                text: textConstants.prompt
                color: @@MUTED@@
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            // Buttons
            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter
                property int btnWidth: Math.max(loginButton.implicitWidth,
                                                shutdownButton.implicitWidth,
                                                rebootButton.implicitWidth, 100) + 16

                Button {
                    id: loginButton
                    text: textConstants.login
                    width: parent.btnWidth
                    height: 40
                    font.pixelSize: 14
                    font.bold: true
                    textColor: @@FOREGROUND@@
                    color: @@ACCENT@@
                    activeColor: @@ACCENT_DIM@@
                    pressedColor: @@SURFACE@@
                    borderColor: @@ACCENT@@
                    onClicked: sddm.login(name.text, password.text, sessionIndex)
                    KeyNavigation.backtab: layoutBox; KeyNavigation.tab: shutdownButton
                }

                Button {
                    id: shutdownButton
                    text: textConstants.shutdown
                    width: parent.btnWidth
                    height: 40
                    font.pixelSize: 14
                    textColor: @@FOREGROUND@@
                    color: @@SURFACE@@
                    activeColor: @@ACCENT_DIM@@
                    pressedColor: @@SURFACE@@
                    borderColor: @@DANGER@@
                    onClicked: sddm.powerOff()
                    KeyNavigation.backtab: loginButton; KeyNavigation.tab: rebootButton
                }

                Button {
                    id: rebootButton
                    text: textConstants.reboot
                    width: parent.btnWidth
                    height: 40
                    font.pixelSize: 14
                    textColor: @@FOREGROUND@@
                    color: @@SURFACE@@
                    activeColor: @@ACCENT_DIM@@
                    pressedColor: @@SURFACE@@
                    borderColor: @@WARNING@@
                    onClicked: sddm.reboot()
                    KeyNavigation.backtab: shutdownButton; KeyNavigation.tab: name
                }
            }
        }
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