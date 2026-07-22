import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1600
    height: 900
    color: backgroundColor

    property color primaryColor: config.primary_color || "#1B75BC"
    property color accentColor: config.accent_color || "#00AEEF"
    property color backgroundColor: config.background_color || "#090D12"
    property color panelColor: config.panel_color || "#F4F6F8"
    property color mutedColor: config.muted_color || "#68717C"
    property color textColor: config.text_color || "#17202A"
    property real uiScale: Math.max(0.78, Math.min(1.15, Math.min(width / 1600, height / 900)))
    property date currentTime: new Date()

    function submitLogin() {
        if (!userBox.currentText) {
            statusText.text = "Select an account to continue."
            statusText.color = "#B42318"
            return
        }

        if (!passwordField.text) {
            statusText.text = "Enter your password."
            statusText.color = "#B42318"
            passwordField.forceActiveFocus()
            return
        }

        statusText.text = "Signing in..."
        statusText.color = mutedColor
        loginButton.enabled = false
        sddm.login(userBox.currentText, passwordField.text, sessionBox.currentIndex)
    }

    function getUserIcon(index) {
        if (index < 0 || !userModel) return ""
        try {
            if (userModel.data) {
                var idx = userModel.index(index, 0)
                var ic = userModel.data(idx, 260)
                if (ic) return ic
            }
        } catch (e) {}
        return ""
    }

    function formatIconUrl(iconPath) {
        if (!iconPath || iconPath === "") return Qt.resolvedUrl("default-user.svg")
        if (iconPath.indexOf("file://") === 0) return iconPath
        if (iconPath.indexOf("/") === 0) return "file://" + iconPath
        return iconPath
    }

    LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Repeater {
        model: 13

        Rectangle {
            x: index * root.width / 12
            width: 1
            height: root.height
            color: "#12FFFFFF"
        }
    }

    Repeater {
        model: 8

        Rectangle {
            y: index * root.height / 7
            width: root.width
            height: 1
            color: "#0CFFFFFF"
        }
    }

    Rectangle {
        anchors.left: parent.left
        width: Math.max(8, root.width * 0.008)
        height: parent.height
        color: accentColor
    }

    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 54 * uiScale
        anchors.topMargin: 42 * uiScale
        spacing: 8 * uiScale

        Image {
            width: 270 * uiScale
            height: 60 * uiScale
            source: Qt.resolvedUrl("logo.svg")
            sourceSize: Qt.size(width, height)
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            smooth: true
        }
    }

    Column {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 54 * uiScale
        anchors.topMargin: 42 * uiScale
        spacing: 2

        Text {
            anchors.right: parent.right
            text: Qt.formatTime(currentTime, "HH:mm")
            color: "#F7F9FB"
            font.pixelSize: 38 * uiScale
            font.weight: Font.Light
        }

        Text {
            anchors.right: parent.right
            text: Qt.formatDate(currentTime, Qt.DefaultLocaleLongDate)
            color: "#A8B2BE"
            font.pixelSize: 14 * uiScale
        }
    }

    Rectangle {
        id: loginPanel
        anchors.centerIn: parent
        width: Math.min(430 * uiScale, root.width - 36)
        height: 570 * uiScale
        color: panelColor
        radius: 8
        border.width: 1
        border.color: "#24FFFFFF"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 38 * uiScale
            spacing: 12 * uiScale

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 88 * uiScale
                Layout.preferredHeight: 88 * uiScale
                radius: width / 2
                color: "#E1E6EB"
                border.width: 3
                border.color: "#FFFFFF"
                clip: true

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    anchors.margins: (status === Image.Ready && source != Qt.resolvedUrl("default-user.svg")) ? 0 : 17 * uiScale
                    source: formatIconUrl(getUserIcon(userBox.currentIndex))
                    sourceSize: Qt.size(width, height)
                    fillMode: (status === Image.Ready && source != Qt.resolvedUrl("default-user.svg")) ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                    smooth: true
                    onStatusChanged: {
                        if (status === Image.Error) {
                            source = Qt.resolvedUrl("default-user.svg")
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Welcome back"
                color: textColor
                font.pixelSize: 27 * uiScale
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 8 * uiScale
                text: "Sign in to your workspace"
                color: mutedColor
                font.pixelSize: 14 * uiScale
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: "Account"
                color: textColor
                font.pixelSize: 13 * uiScale
                font.weight: Font.DemiBold
            }

            QQC2.ComboBox {
                id: userBox
                Layout.fillWidth: true
                Layout.preferredHeight: 44 * uiScale
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex
                font.pixelSize: 15 * uiScale

                delegate: QQC2.ItemDelegate {
                    width: userBox.width
                    highlighted: userBox.highlightedIndex === index
                    contentItem: RowLayout {
                        spacing: 10 * uiScale
                        Rectangle {
                            width: 24 * uiScale
                            height: 24 * uiScale
                            radius: width / 2
                            color: "#E1E6EB"
                            clip: true
                            Image {
                                anchors.fill: parent
                                anchors.margins: (status === Image.Ready && source != Qt.resolvedUrl("default-user.svg")) ? 0 : 4 * uiScale
                                source: formatIconUrl(model.icon)
                                sourceSize: Qt.size(width, height)
                                fillMode: (status === Image.Ready && source != Qt.resolvedUrl("default-user.svg")) ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                smooth: true
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        source = Qt.resolvedUrl("default-user.svg")
                                    }
                                }
                            }
                        }
                        Text {
                            text: model.realName ? (model.realName + " (" + model.name + ")") : model.name
                            color: textColor
                            font.pixelSize: 14 * uiScale
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Text {
                text: "Password"
                color: textColor
                font.pixelSize: 13 * uiScale
                font.weight: Font.DemiBold
            }

            QQC2.TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 44 * uiScale
                placeholderText: "Enter password"
                echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                selectByMouse: true
                font.pixelSize: 15 * uiScale
                color: textColor
                background: Rectangle {
                    color: "#FFFFFF"
                    radius: 5
                    border.width: passwordField.activeFocus ? 2 : 1
                    border.color: passwordField.activeFocus ? accentColor : "#BAC2CB"
                }
                onAccepted: root.submitLogin()
            }

            RowLayout {
                Layout.fillWidth: true

                QQC2.CheckBox {
                    id: showPassword
                    text: "Show password"
                    font.pixelSize: 12 * uiScale
                }

                Item { Layout.fillWidth: true }

                QQC2.ComboBox {
                    id: sessionBox
                    Layout.preferredWidth: 150 * uiScale
                    Layout.preferredHeight: 36 * uiScale
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex
                    font.pixelSize: 12 * uiScale
                }
            }

            Text {
                id: statusText
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * uiScale
                text: ""
                color: mutedColor
                font.pixelSize: 12 * uiScale
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            QQC2.Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 46 * uiScale
                hoverEnabled: true
                contentItem: Text {
                    text: loginButton.enabled ? "Sign in" : "Signing in..."
                    color: "#FFFFFF"
                    font.pixelSize: 15 * uiScale
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: !loginButton.enabled ? "#8190A0"
                        : loginButton.down ? Qt.darker(primaryColor, 1.16)
                        : loginButton.hovered ? Qt.lighter(primaryColor, 1.10)
                        : primaryColor
                    radius: 5
                }
                onClicked: root.submitLogin()
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28 * uiScale
        spacing: 14 * uiScale

        QQC2.Button {
            text: "Restart"
            flat: true
            onClicked: sddm.reboot()
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 18 * uiScale
            color: "#43505D"
        }

        QQC2.Button {
            text: "Shut down"
            flat: true
            onClicked: sddm.powerOff()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            loginButton.enabled = true
            passwordField.clear()
            statusText.text = "That password was not accepted. Try again."
            statusText.color = "#B42318"
            passwordField.forceActiveFocus()
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}
