import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: win
    visible: true
    width: 560
    height: 440
    minimumWidth: 440
    minimumHeight: 410
    title: qsTr("PDF Press")
    Material.theme: Material.Dark
    Material.accent: "#b4cec2"
    property url selected
    property url destination
    property bool working: false
    FileDialog {
        id: picker
        nameFilters: [qsTr("PDF files (*.pdf *.PDF)")]
        onAccepted: { win.selected = selectedFile; status.text = "" }
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
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 10
        Label { text: win.title; font.pixelSize: 30; font.bold: true }
        RowLayout {
            Button { Material.roundedScale: Material.NotRounded; text: qsTr("Choose PDF…"); enabled: !win.working; onClicked: picker.open() }
            Label { Layout.fillWidth: true; elide: Text.ElideMiddle; text: win.selected.toString() ? decodeURIComponent(win.selected.toString().split("/").pop()) : qsTr("No file selected") }
        }
        Label { text: qsTr("Image quality") }
        ComboBox { id: quality; Layout.fillWidth: true; enabled: !win.working; model: [qsTr("High · 200 dpi"), qsTr("Balanced · 144 dpi"), qsTr("Smallest · 85 dpi")]; currentIndex: 1 }
        Button {
            Material.roundedScale: Material.NotRounded
            highlighted: true
            enabled: !win.working && win.selected.toString() !== ""
            text: win.working ? qsTr("Compressing…") : qsTr("Compress PDF")
            onClicked: { win.working = true; status.text = ""; compressor.compress(win.selected, quality.currentIndex, win.destination) }
        }
        Button {
            Layout.fillWidth: true
            flat: true
            enabled: !win.working
            font.underline: true
            text: win.destination.toString()
                  ? qsTr("Save copy in %1").arg(compressor.folderPath(win.destination))
                  : qsTr("Save copy beside the original")
            contentItem: Label {
                text: parent.text
                font: parent.font
                textFormat: Text.PlainText
                elide: Text.ElideMiddle
                verticalAlignment: Text.AlignVCenter
                color: win.Material.accent
            }
            onClicked: folderPicker.open()
        }
        Label { id: status; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText }
        Item { Layout.fillHeight: true }
    }
}
