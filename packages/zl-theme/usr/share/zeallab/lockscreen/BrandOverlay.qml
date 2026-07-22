import QtQuick 2.15

Item {
    id: root

    property color primaryColor: "#1B75BC"
    property color accentColor: "#00AEEF"
    property color backgroundColor: "#090D12"
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

    Rectangle {
        id: cardPanel
        anchors.centerIn: parent
        width: Math.min(430 * root.uiScale, root.width - 36)
        height: Math.min(520 * root.uiScale, root.height - 60)
        visible: root.panelVisible
        color: "#FFFFFF"
        radius: 8
        border.width: 1
        border.color: "#551B75BC"

        Column {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 24 * root.uiScale
            spacing: 4 * root.uiScale

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.currentTime, "HH:mm")
                color: "#1A202C"
                font.pixelSize: 36 * root.uiScale
                font.weight: Font.DemiBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(root.currentTime, Qt.DefaultLocaleLongDate)
                color: "#4A5568"
                font.pixelSize: 13 * root.uiScale
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