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
    property bool working: false
    FileDialog {
        id: picker
        nameFilters: [qsTr("PDF files (*.pdf *.PDF)")]
        onAccepted: { win.selected = selectedFile; status.text = "" }
    }
    Connections {
        target: compressor
        function onDone(message) { win.working = false; status.text = message }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 10
        Label { text: qsTr("Compress a PDF"); font.pixelSize: 30 }
        Label { text: qsTr("The smaller copy is saved beside your original.") }
        RowLayout {
            Button { text: qsTr("Choose PDF…"); enabled: !win.working; onClicked: picker.open() }
            Label { Layout.fillWidth: true; elide: Text.ElideMiddle; text: win.selected.toString() ? decodeURIComponent(win.selected.toString().split("/").pop()) : qsTr("No file selected") }
        }
        Label { text: qsTr("Image quality") }
        ComboBox { id: quality; Layout.fillWidth: true; enabled: !win.working; model: [qsTr("High · 200 dpi"), qsTr("Balanced · 144 dpi"), qsTr("Smallest · 85 dpi")]; currentIndex: 1 }
        Button {
            highlighted: true
            enabled: !win.working && win.selected.toString() !== ""
            text: win.working ? qsTr("Compressing…") : qsTr("Compress PDF")
            onClicked: { win.working = true; status.text = ""; compressor.compress(win.selected, quality.currentIndex) }
        }
        Label { id: status; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText }
        Item { Layout.fillHeight: true }
    }
}
