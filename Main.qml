import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: win
    width: 640
    height: 560
    minimumWidth: 360
    minimumHeight: 400
    visible: true
    title: qsTr("PDF Press")
    color: "#191c1b"
    font.family: "Inter"
    font.pixelSize: 14
    Material.theme: Material.Dark
    Material.accent: accent
    readonly property color accent: "#b8d0c2"
    readonly property color ink: "#eef0ed"
    readonly property color muted: "#abb4ae"
    readonly property color line: "#465049"
    property url selected
    property var details: ({})
    property url destination
    property bool working: false

    function selectFile(url) {
        const info = compressor.fileDetails(url)
        if (!info.name) {
            status.text = qsTr("Choose a readable PDF file.")
            return
        }
        selected = url
        details = info
        status.text = ""
    }

    FileDialog {
        id: picker
        nameFilters: [qsTr("PDF files (*.pdf *.PDF)")]
        onAccepted: win.selectFile(selectedFile)
    }
    FolderDialog {
        id: folderPicker
        title: qsTr("Choose where to save the compressed copy")
        onAccepted: { win.destination = selectedFolder; status.text = "" }
    }
    Connections {
        target: compressor
        function onDone(message) { win.working = false; status.text = message }
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        contentHeight: Math.max(win.height, form.implicitHeight + 64)
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: form
            width: Math.min(480, scroll.availableWidth - 48)
            x: (scroll.availableWidth - width) / 2
            y: 32
            spacing: 0

            Label { text: win.title; font.pixelSize: 33; color: win.ink }
            Label {
                Layout.topMargin: 5
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Smaller PDFs, with control over image quality.")
                color: win.muted
            }

            Button {
                id: zone
                Layout.topMargin: 26
                Layout.fillWidth: true
                Layout.preferredHeight: 108
                enabled: !win.working
                text: win.details.name || qsTr("Drop a PDF here, or click to choose")
                Accessible.name: text
                onClicked: picker.open()
                background: Rectangle {
                    radius: 6
                    color: zone.hovered || drop.containsDrag ? "#2a312d" : "#212623"
                    border.color: drop.containsDrag || zone.visualFocus ? win.accent : win.line
                }
                contentItem: ColumnLayout {
                    spacing: 6
                    Item { Layout.fillHeight: true }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: zone.text
                        textFormat: Text.PlainText
                        elide: Text.ElideMiddle
                        color: win.ink
                        font.pixelSize: 16
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: win.details.size || qsTr("One file at a time · processed on your device")
                        color: win.muted
                        font.pixelSize: 13
                        font.features: { "tnum": 1 }
                    }
                    Item { Layout.fillHeight: true }
                }
                DropArea {
                    id: drop
                    anchors.fill: parent
                    onEntered: drag => { drag.accepted = drag.hasUrls && !win.working }
                    onDropped: event => {
                        if (event.urls.length === 1) win.selectFile(event.urls[0])
                        else status.text = qsTr("Drop one PDF at a time.")
                    }
                }
            }

            Label { Layout.topMargin: 22; text: qsTr("Image quality"); color: win.ink }
            ComboBox {
                id: quality
                Layout.topMargin: 6
                Layout.preferredWidth: 205
                enabled: !win.working
                Accessible.name: qsTr("Image quality")
                model: [qsTr("High · 200 dpi"), qsTr("Balanced · 144 dpi"), qsTr("Smallest · 85 dpi")]
                currentIndex: 1
                font.features: { "tnum": 1 }
                background: Rectangle {
                    implicitHeight: 40
                    radius: 4
                    color: "#242926"
                    border.color: quality.visualFocus ? win.accent : win.line
                }
            }
            RowLayout {
                Layout.topMargin: 14
                Layout.fillWidth: true
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    font.pixelSize: 13
                    color: win.muted
                    text: win.destination.toString()
                          ? qsTr("Save copy in %1").arg(compressor.folderPath(win.destination))
                          : qsTr("The compressed copy will be saved next to the original PDF.")
                }
                Button {
                    id: change
                    flat: true
                    enabled: !win.working
                    text: qsTr("Change…")
                    Accessible.name: qsTr("Change save location")
                    font.capitalization: Font.MixedCase
                    font.pixelSize: 13
                    Material.foreground: win.accent
                    horizontalPadding: 5
                    onClicked: folderPicker.open()
                }
            }
            Button {
                id: submit
                Layout.topMargin: 12
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                text: win.working ? qsTr("Compressing…") : qsTr("Compress PDF")
                enabled: !!win.details.name && !win.working
                contentItem: Label {
                    text: submit.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: submit.enabled ? "#19251e" : "#9aa39d"
                    font.weight: Font.Medium
                }
                background: Rectangle {
                    radius: 4
                    color: !submit.enabled ? "#2b302d" : submit.down ? "#a5baae" : submit.hovered ? "#cadcd1" : win.accent
                    border.color: submit.visualFocus ? win.ink : color
                }
                onClicked: {
                    win.working = true
                    status.text = ""
                    compressor.compress(win.selected, quality.currentIndex, win.destination)
                }
            }
            Label {
                id: status
                visible: text.length > 0
                Layout.fillWidth: true
                Layout.topMargin: 12
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                color: win.muted
                font.features: { "tnum": 1 }
            }
        }
    }
}
