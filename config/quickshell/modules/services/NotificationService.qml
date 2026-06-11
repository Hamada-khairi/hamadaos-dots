// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Notification Daemon (real org.freedesktop.Notifications server)
// ═══════════════════════════════════════════════════════════════════════════════
// Quickshell IS the notification daemon — dunst is disabled in HyDE's
// config.toml. Every notify-send, browser alert, and Discord ping lands
// here and renders as an animated HamadaOS banner with working action
// buttons.
//
// Simplified from end-4/dots-hyprland services/Notifications.qml.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.modules.common

Singleton {
    id: root

    component Notif: QtObject {
        required property int notifId
        property Notification notification
        property bool popup: true
        property string appName: notification?.appName ?? ""
        property string appIcon: notification?.appIcon ?? ""
        property string summary: notification?.summary ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property var actions: notification?.actions ?? []
        property double time: Date.now()

        onNotificationChanged: {
            if (notification === null) root.discard(notifId)
        }
    }

    component NotifTimer: Timer {
        required property int notifId
        running: true
        onTriggered: { root.timeout(notifId); destroy() }
    }

    property list<Notif> list: []
    readonly property var popupList: list.filter(n => n.popup)
    property int unread: 0

    Component { id: notifComponent; Notif { } }
    Component { id: timerComponent; NotifTimer { } }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true
            const notif = notifComponent.createObject(root, {
                notifId: notification.id,
                notification: notification
            })
            root.list = [...root.list, notif]
            root.unread++

            if (Config.options.doNotDisturb) {
                notif.popup = false
            } else if (notification.expireTimeout !== 0) {
                timerComponent.createObject(root, {
                    notifId: notification.id,
                    interval: notification.expireTimeout > 0
                        ? notification.expireTimeout
                        : Config.options.notificationTimeout
                })
            }
        }
    }

    function timeout(id) {
        const n = list.find(n => n.notifId === id)
        if (n) { n.popup = false; refreshList() }
    }

    function discard(id) {
        const index = list.findIndex(n => n.notifId === id)
        if (index !== -1) {
            list.splice(index, 1)
            refreshList()
        }
        const tracked = server.trackedNotifications.values.find(n => n.id === id)
        if (tracked) tracked.dismiss()
    }

    function discardAll() {
        root.list = []
        server.trackedNotifications.values.forEach(n => n.dismiss())
        unread = 0
    }

    function invokeAction(id, identifier) {
        const tracked = server.trackedNotifications.values.find(n => n.id === id)
        const action = tracked?.actions.find(a => a.identifier === identifier)
        if (action) action.invoke()
        discard(id)
    }

    function refreshList() { root.list = root.list.slice(0) }
}
