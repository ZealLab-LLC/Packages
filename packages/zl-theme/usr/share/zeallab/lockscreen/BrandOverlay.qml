import QtQuick 2.15

Item {
    id: root

    property color primaryColor: "#1B75BC"
    property color accentColor: "#00AEEF"
    property color backgroundColor: "#090D12"
    property color panelColor: "#F4F6F8"
    property bool panelVisible: true
    property real uiScale: Math.max(0.78, Math.min(1.15, Math.min(width / 1600, height / 900)))
    property date currentTime: new Date()

    Rectangle {
        anchors.fill: parent
        color: root.backgroundColor
    }

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
        color: root.accentColor
    }

    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 54 * root.uiScale
        anchors.topMargin: 42 * root.uiScale
        spacing: 8 * root.uiScale

        Image {
            width: 270 * root.uiScale
            height: 60 * root.uiScale
            source: "file:///usr/share/zeallab/assets/logo.svg"
            sourceSize: Qt.size(width, height)
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            smooth: true
        }
    }

    Item {
        id: lockCard
        anchors.centerIn: parent
        width: Math.min(430 * root.uiScale, root.width - 36)
        height: Math.min(520 * root.uiScale, root.height - 60)
        visible: root.panelVisible

        // Layered translucent rectangles fake a soft drop shadow so the card
        // reads as raised off the background. Keep in sync with the login card
        // in /usr/share/sddm/themes/zeal-blade/Main.qml.
        Repeater {
            model: 6

            Rectangle {
                readonly property int depth: 6 - index
                anchors.fill: parent
                anchors.leftMargin: -depth * 3
                anchors.rightMargin: -depth * 3
                anchors.topMargin: -depth
                anchors.bottomMargin: -depth * 5
                radius: cardPanel.radius + depth * 3
                color: "#000000"
                opacity: 0.05
            }
        }

        Rectangle {
            id: cardPanel
            anchors.fill: parent
            radius: 14
            border.width: 1
            border.color: "#66FFFFFF"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(root.panelColor, 1.04) }
                GradientStop { position: 0.55; color: root.panelColor }
                GradientStop { position: 1.0; color: Qt.darker(root.panelColor, 1.12) }
            }

            // Highlight across the top half, fading out before the bottom so
            // the panel looks convex.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                height: parent.height * 0.45
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#CCFFFFFF" }
                    GradientStop { position: 1.0; color: "#00FFFFFF" }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                color: "transparent"
                border.width: 1
                border.color: "#59FFFFFF"
            }

            Column {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 24 * root.uiScale
                spacing: 4 * root.uiScale

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.currentTime, "HH:mm")
                    color: "#17202A"
                    font.pixelSize: 36 * root.uiScale
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.currentTime.toLocaleDateString(Qt.locale(), Locale.LongFormat)
                    color: "#68717C"
                    font.pixelSize: 13 * root.uiScale
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }
}