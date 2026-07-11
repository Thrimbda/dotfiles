import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

ShellRoot {
    FileView {
        id: memorySnapshot
        path: "/run/bluetooth-predeploy/notifs-memory.json"
        printErrors: true
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            if (!Notifs.loaded)
                return;
            memorySnapshot.setText(JSON.stringify(Notifs.list.map(notif => ({
                time: notif.time,
                id: notif.notificationId,
                summary: notif.summary,
                body: notif.body,
                appIcon: notif.appIcon,
                appName: notif.appName,
                image: notif.image,
                expireTimeout: notif.expireTimeout,
                urgency: notif.urgency,
                resident: notif.resident,
                hasActionIcons: notif.hasActionIcons,
                actions: notif.actions
            }))));
        }
    }
}
