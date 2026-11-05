import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "vornashev.yandex-music"

  readonly property var logic: logicLoader.item
  readonly property bool hasTrack: logic ? logic.hasTrack : false
  readonly property bool playing: logic ? logic.playing : false
  readonly property bool opened: logic ? logic.opened : false
  readonly property bool popoutSwitchClosing: logic ? logic.popoutSwitchClosing : false
  // Suppress Omarchy's extra underline while this widget's popup is open.
  readonly property real openPanelIndicatorWidth: 0.01
  readonly property real openPanelIndicatorHeight: 0.01

  property bool interactive: true
  property bool pressable: true
  property bool concealed: false

  function triggerPress(button) {
    if (button === Qt.MiddleButton) {
      if (logic) logic.action("pause")
    } else {
      if (logic) logic.toggle()
    }
  }

  function injectLogic() {
    if (!logic) return
    logic.bar = root.bar
    logic.settings = root.settings
    logic.anchorItem = root
    logic.hostWidget = root
  }
  function open() {
    console.log("[YandexMusic] BarWidget.open called, logic:", logic)
    if (logic) logic.open()
  }
  function close() {
    console.log("[YandexMusic] BarWidget.close called")
    if (logic) logic.close()
  }
  function toggle() {
    console.log("[YandexMusic] BarWidget.toggle called, logic:", logic)
    if (logic) logic.toggle()
  }
  function closeForPopoutSwitch() { if (logic) logic.closeForPopoutSwitch() }

  implicitWidth: root.vertical ? root.barSize : (playerLoader.item ? playerLoader.item.implicitWidth : 0)
  implicitHeight: root.vertical ? root.barSize : (playerLoader.item ? playerLoader.item.implicitHeight : barSize)
  onBarChanged: injectLogic()
  onSettingsChanged: injectLogic()

  Loader {
    id: logicLoader
    active: true
    visible: false
    source: Qt.resolvedUrl("WidgetLogic.qml")
    onLoaded: {
      root.injectLogic()
      Qt.callLater(root.injectLogic)
    }
  }

  Loader {
    id: playerLoader
    anchors.fill: parent
    active: true
    source: Qt.resolvedUrl("BarPlayer.qml")
    onLoaded: {
      item.bar = root.bar
      item.logic = root.logic
      item.hostWidget = root
      root.injectLogic()
    }
  }

  Connections {
    target: root
    function onBarChanged() { if (playerLoader.item) playerLoader.item.bar = root.bar }
    function onLogicChanged() {
      if (playerLoader.item) playerLoader.item.logic = root.logic
      root.injectLogic()
    }
  }
}
