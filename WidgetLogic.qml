import QtQuick

Item {
  id: root
  property var bar: null
  property var settings: ({})
  property var anchorItem: null
  property var hostWidget: null
  readonly property var snapshot: session.snapshot
  readonly property bool hasTrack: String(snapshot.title || "") !== ""
  readonly property bool loading: session.loading
  readonly property string error: session.error
  readonly property bool playing: snapshot.playing === true
  readonly property string shortTitle: {
    var title = String(snapshot.title || "")
    return title.length > 28 ? title.slice(0, 28) + "…" : title
  }
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = (root.anchorItem && root.anchorItem.coverItem) ? root.anchorItem.coverItem : root.anchorItem
    target.hostWidget = root.hostWidget
    target.session = session
  }
  function open() {
    console.log("[YandexMusic] WidgetLogic.open called, panelLoader.item:", panelLoader.item)
    if (panelLoader.item) panelLoader.item.open()
  }
  function close() {
    console.log("[YandexMusic] WidgetLogic.close called")
    if (panelLoader.item) panelLoader.item.close()
  }
  function toggle() {
    console.log("[YandexMusic] WidgetLogic.toggle called, panelLoader.item:", panelLoader.item)
    if (panelLoader.item) panelLoader.item.toggle()
  }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function showArtist(artistId) {
    if (!artistId) return
    if (panelLoader.item) {
      if (panelLoader.item.selectPage) panelLoader.item.selectPage(2)
      else panelLoader.item.page = 2
    }
    open()
    session.openArtistEventually(artistId)
  }

  function refresh() { return session.refresh() }
  function transport(intent, payload) { return session.transport(intent, payload) }
  function queueVolume(value) { return session.queueVolume(value) }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  onAnchorItemChanged: injectPanel()

  MusicSession {
    id: session
    panelOpened: root.opened
  }
  Loader {
    id: panelLoader
    active: true
    visible: false
    source: Qt.resolvedUrl("Panel.qml")
    onStatusChanged: console.log("[YandexMusic] panelLoader status:", status, "item:", item)
    onLoaded: {
      console.log("[YandexMusic] panelLoader loaded successfully! item:", item)
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }
}
