/***************************************************************************
 * Hyprsimple SDDM Theme
 * Minimal theme matching Hyprsimple color palette
 * Background: #0B0F19, Accent: #38BDF8, Foreground: #D8D9F7
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
            errorMessage.color = "#38BDF8"
            errorMessage.text = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            password.text = ""
            errorMessage.color = "#F27A9B"
            errorMessage.text = textConstants.loginFailed
        }
        function onInformationMessage(message) {
            errorMessage.color = "#F27A9B"
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
        color: "#0B0F19"
        opacity: 0.6
    }

    // Main login panel
    Rectangle {
        id: loginPanel
        anchors.centerIn: parent
        width: Math.max(360, mainColumn.implicitWidth + 60)
        height: mainColumn.implicitHeight + 60
        radius: 12
        color: "#0B0F19"
        border.color: "#38BDF8"
        border.width: 2

        Column {
            id: mainColumn
            anchors.centerIn: parent
            spacing: 16

            // Welcome text
            Text {
                id: welcomeText
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#D8D9F7"
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
                    color: "#D8D9F7"
                    font.bold: true
                    font.pixelSize: 13
                }

                TextBox {
                    id: name
                    width: parent.width; height: 38
                    text: userModel.lastUser
                    font.pixelSize: 15
                    textColor: "#D8D9F7"
                    color: "#1E2437"
                    borderColor: "#5C6589"
                    focusColor: "#38BDF8"
                    hoverColor: "#7AA2F7"
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
                    color: "#D8D9F7"
                    font.bold: true
                    font.pixelSize: 13
                }

                PasswordBox {
                    id: password
                    width: parent.width; height: 38
                    font.pixelSize: 15
                    textColor: "#D8D9F7"
                    color: "#1E2437"
                    borderColor: "#5C6589"
                    focusColor: "#38BDF8"
                    hoverColor: "#7AA2F7"
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
                    color: "#D8D9F7"
                    font.bold: true
                    font.pixelSize: 13
                }

                ComboBox {
                    id: session
                    width: parent.width; height: 38
                    font.pixelSize: 15
                    color: "#1E2437"
                    borderColor: "#5C6589"
                    focusColor: "#38BDF8"
                    hoverColor: "#7AA2F7"
                    textColor: "#D8D9F7"
                    menuColor: "#1E2437"
                    arrowColor: "#38BDF8"
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
                    color: "#D8D9F7"
                    font.bold: true
                    font.pixelSize: 13
                }

                LayoutBox {
                    id: layoutBox
                    width: parent.width; height: 38
                    font.pixelSize: 15
                    color: "#D8D9F7"
                    KeyNavigation.backtab: session; KeyNavigation.tab: loginButton
                }
            }

            // Error/info message
            Text {
                id: errorMessage
                anchors.horizontalCenter: parent.horizontalCenter
                text: textConstants.prompt
                color: "#5C6589"
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
                    textColor: "#D8D9F7"
                    color: "#38BDF8"
                    activeColor: "#7AA2F7"
                    pressedColor: "#2E3A59"
                    borderColor: "#38BDF8"
                    onClicked: sddm.login(name.text, password.text, sessionIndex)
                    KeyNavigation.backtab: layoutBox; KeyNavigation.tab: shutdownButton
                }

                Button {
                    id: shutdownButton
                    text: textConstants.shutdown
                    width: parent.btnWidth
                    height: 40
                    font.pixelSize: 14
                    textColor: "#D8D9F7"
                    color: "#1E2437"
                    activeColor: "#2E3A59"
                    pressedColor: "#2E3A59"
                    borderColor: "#F27A9B"
                    onClicked: sddm.powerOff()
                    KeyNavigation.backtab: loginButton; KeyNavigation.tab: rebootButton
                }

                Button {
                    id: rebootButton
                    text: textConstants.reboot
                    width: parent.btnWidth
                    height: 40
                    font.pixelSize: 14
                    textColor: "#D8D9F7"
                    color: "#1E2437"
                    activeColor: "#2E3A59"
                    pressedColor: "#2E3A59"
                    borderColor: "#F2C47E"
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
        color: "#D8D9F7"
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