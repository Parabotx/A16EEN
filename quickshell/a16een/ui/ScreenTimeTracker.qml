import QtQuick
import Quickshell
import Quickshell.Io

// Records active, focused-window time. Input-idle detection is event driven via swayidle.
Item {
    id: root

    width: 0
    height: 0
    visible: false

    property int focusedWindowId: -1
    property var windows: []
    property bool locked: false
    property bool idle: false
    property var usageData: ({ version: 1, days: ({}) })
    property bool usageLoaded: false
    property bool usageDirty: false
    property int clockRevision: 0
    // Sampling baseline is recreated after reload, idle, lock, or a long event-loop pause.
    property double lastSampleMs: 0
    property double pendingActiveMs: 0

    readonly property string usagePath: Quickshell.stateDir + "/screen-time.json"

    readonly property string todayKey: {
        root.clockRevision
        return root.dateKey(new Date())
    }

    readonly property var todayRecord: {
        const days = root.usageData && root.usageData.days ? root.usageData.days : ({})
        return days[root.todayKey] || ({ totalSeconds: 0, apps: ({}) })
    }

    readonly property int todaySeconds: Math.max(0, Number(root.todayRecord.totalSeconds) || 0)

    readonly property int weekSeconds: {
        root.clockRevision
        const days = root.usageData && root.usageData.days ? root.usageData.days : ({})
        let total = 0
        const date = new Date()
        for (let offset = 0; offset < 7; offset++) {
            total += Math.max(0, Number((days[root.dateKey(date)] || {}).totalSeconds) || 0)
            date.setDate(date.getDate() - 1)
        }
        return total
    }

    readonly property int monthSeconds: {
        root.clockRevision
        const days = root.usageData && root.usageData.days ? root.usageData.days : ({})
        const monthPrefix = root.todayKey.slice(0, 7)
        let total = 0
        for (const dayKey in days) {
            if (String(dayKey).slice(0, 7) === monthPrefix)
                total += Math.max(0, Number(days[dayKey].totalSeconds) || 0)
        }
        return total
    }

    readonly property var topApps: {
        const apps = root.todayRecord.apps || ({})
        return Object.keys(apps).map(id => ({
            id: id,
            name: String(apps[id].name || id),
            seconds: Math.max(0, Number(apps[id].seconds) || 0)
        })).filter(app => app.seconds > 0)
          .sort((a, b) => b.seconds - a.seconds || a.name.localeCompare(b.name))
    }

    readonly property var weekApps: {
        root.clockRevision
        return root.aggregateApps("week")
    }

    readonly property var monthApps: {
        root.clockRevision
        return root.aggregateApps("month")
    }

    function aggregateApps(period) {
        const days = root.usageData && root.usageData.days ? root.usageData.days : ({})
        const eligibleDates = ({})
        if (period === "week") {
            const date = new Date()
            for (let offset = 0; offset < 7; offset++) {
                eligibleDates[root.dateKey(date)] = true
                date.setDate(date.getDate() - 1)
            }
        }

        const monthPrefix = root.todayKey.slice(0, 7)
        const totals = ({})
        for (const dayKey in days) {
            const includeDay = period === "month"
                ? String(dayKey).slice(0, 7) === monthPrefix
                : eligibleDates[dayKey] === true
            if (!includeDay)
                continue

            const apps = days[dayKey].apps || ({})
            for (const appId in apps) {
                const app = apps[appId] || ({})
                const current = totals[appId] || ({ name: String(app.name || appId), seconds: 0 })
                totals[appId] = {
                    name: String(app.name || current.name || appId),
                    seconds: Math.max(0, Number(current.seconds) || 0)
                        + Math.max(0, Number(app.seconds) || 0)
                }
            }
        }

        return Object.keys(totals).map(id => ({
            id: id,
            name: String(totals[id].name || id),
            seconds: Math.max(0, Number(totals[id].seconds) || 0)
        })).filter(app => app.seconds > 0)
          .sort((a, b) => b.seconds - a.seconds || a.name.localeCompare(b.name))
    }

    readonly property var focusedWindow: {
        if (root.focusedWindowId < 0)
            return null
        return root.windows.find(window => Number(window.id) === Number(root.focusedWindowId)) || null
    }

    readonly property bool trackingActive:
        root.usageLoaded && !root.locked && !root.idle
        && root.focusedWindowId >= 0 && root.activeAppInfo() !== null

    readonly property string statusText: root.locked ? "PAUSED · SCREEN LOCKED"
        : (root.idle ? "PAUSED · IDLE"
        : (root.trackingActive ? "TRACKING ACTIVE WINDOW" : "WAITING FOR AN ACTIVE WINDOW"))

    readonly property string currentAppName: {
        const info = root.activeAppInfo()
        return info ? info.name : "No active application"
    }

    function dateKey(date) {
        const year = date.getFullYear()
        const month = String(date.getMonth() + 1).padStart(2, "0")
        const day = String(date.getDate()).padStart(2, "0")
        return year + "-" + month + "-" + day
    }

    function normalizeId(value) {
        return String(value || "").toLowerCase()
            .replace(/\\.desktop$/, "")
            .replace(/[^a-z0-9]/g, "")
    }

    function activeAppInfo() {
        const window = root.focusedWindow
        if (!window)
            return null

        // Only count real application windows. Falling back to the title made
        // Quickshell/A16EEN surfaces look like apps during shell restarts.
        const rawId = String(window.app_id || window.appId || "").trim()
        if (!rawId)
            return null

        const normalized = root.normalizeId(rawId)
        const internalAppPrefixes = [
            "quickshell", "orgquickshell", "a16een", "orga16een",
            "niri", "orgniri", "swaylock", "orgswaylock", "gtklock", "orggtklock"
        ]
        if (internalAppPrefixes.some(prefix => normalized.startsWith(prefix)))
            return null

        const leaf = root.normalizeId(rawId.split(".").pop())
        const entries = [...DesktopEntries.applications.values]
        const entry = entries.find(candidate => {
            const candidateId = root.normalizeId(candidate.id || candidate.desktopFile || "")
            const candidateLeaf = root.normalizeId(String(candidate.id || candidate.desktopFile || "").split(".").pop())
            const name = root.normalizeId(candidate.name || "")
            const genericName = root.normalizeId(candidate.genericName || "")
            return candidateId === normalized
                || candidateLeaf === leaf
                || name === normalized
                || name === leaf
                || genericName === normalized
                || genericName === leaf
        })

        return {
            id: normalized || ("window" + String(window.id)),
            name: entry ? String(entry.name || rawId) : rawId
        }
    }

    function setIdleState(value) {
        const nextValue = value === true
        if (root.idle === nextValue)
            return
        root.idle = nextValue
        root.lastSampleMs = 0
        root.pendingActiveMs = 0
        if (nextValue)
            saveTimer.restart()
    }

    function loadUsage(rawText) {
        const cleanedDays = ({})
        try {
            const parsed = JSON.parse(String(rawText || "{}"))
            const storedDays = parsed && parsed.days && typeof parsed.days === "object"
                ? parsed.days : ({})

            for (const dayKey in storedDays) {
                if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(dayKey))
                    continue

                const record = storedDays[dayKey] || ({})
                const apps = ({})
                const storedApps = record.apps && typeof record.apps === "object" ? record.apps : ({})
                for (const appId in storedApps) {
                    const app = storedApps[appId] || ({})
                    const seconds = Math.max(0, Math.floor(Number(app.seconds) || 0))
                    if (seconds > 0) {
                        apps[appId] = {
                            name: String(app.name || appId),
                            seconds: seconds
                        }
                    }
                }

                const totalSeconds = Math.max(0, Math.floor(Number(record.totalSeconds) || 0))
                if (totalSeconds > 0 || Object.keys(apps).length > 0) {
                    cleanedDays[dayKey] = {
                        totalSeconds: Math.max(totalSeconds, Object.keys(apps).reduce((sum, id) => sum + apps[id].seconds, 0)),
                        apps: apps
                    }
                }
            }
        } catch (error) {
            console.warn("A16EEN screen-time history could not be read:", error)
        }

        const keys = Object.keys(cleanedDays).sort()
        while (keys.length > 90)
            delete cleanedDays[keys.shift()]

        root.usageData = { version: 1, days: cleanedDays }
        root.usageLoaded = true
        root.clockRevision++
    }

    function recordSecond() {
        root.clockRevision++
        const now = Date.now()

        if (!root.usageLoaded || !root.trackingActive) {
            root.lastSampleMs = 0
            root.pendingActiveMs = 0
            return
        }

        const info = root.activeAppInfo()
        if (!info || !info.id) {
            root.lastSampleMs = 0
            root.pendingActiveMs = 0
            return
        }

        // Establish a fresh baseline after startup, focus loss, or idle.
        // This prevents a restart / suspended event loop from being credited as usage.
        if (root.lastSampleMs <= 0) {
            root.lastSampleMs = now
            return
        }

        const elapsedMs = now - root.lastSampleMs
        root.lastSampleMs = now
        if (!Number.isFinite(elapsedMs) || elapsedMs <= 0 || elapsedMs > 2500) {
            root.pendingActiveMs = 0
            return
        }

        root.pendingActiveMs += elapsedMs
        const elapsedSeconds = Math.floor(root.pendingActiveMs / 1000)
        if (elapsedSeconds < 1)
            return
        root.pendingActiveMs -= elapsedSeconds * 1000

        const key = root.dateKey(new Date())
        const oldDays = root.usageData && root.usageData.days ? root.usageData.days : ({})
        const oldDay = oldDays[key] || ({ totalSeconds: 0, apps: ({}) })
        const nextDays = ({})
        for (const day in oldDays)
            nextDays[day] = oldDays[day]

        const nextApps = ({})
        const oldApps = oldDay.apps || ({})
        for (const id in oldApps)
            nextApps[id] = oldApps[id]

        const oldApp = nextApps[info.id] || ({ seconds: 0, name: info.name })
        nextApps[info.id] = {
            name: info.name,
            seconds: Math.max(0, Number(oldApp.seconds) || 0) + elapsedSeconds
        }

        const previousTotal = Math.max(0, Number(oldDay.totalSeconds) || 0)
        const nextTotal = previousTotal + elapsedSeconds
        nextDays[key] = { totalSeconds: nextTotal, apps: nextApps }

        // Keep enough history for the full current calendar month and weekly totals.
        const keys = Object.keys(nextDays).sort()
        while (keys.length > 90)
            delete nextDays[keys.shift()]

        root.usageData = { version: 1, days: nextDays }
        root.usageDirty = true

        // Save on each 15-second boundary crossed, including delayed timer ticks.
        if (Math.floor(nextTotal / 15) > Math.floor(previousTotal / 15))
            saveTimer.restart()
    }

    function flushUsage() {
        if (!root.usageLoaded || !root.usageDirty)
            return
        usageFile.setText(JSON.stringify(root.usageData))
        root.usageDirty = false
    }

    FileView {
        id: usageFile
        path: root.usagePath
        preload: true
        printErrors: false
        atomicWrites: true

        onLoaded: root.loadUsage(usageFile.text())
        onLoadFailed: root.loadUsage("{}")
    }

    Timer {
        id: trackerTimer
        interval: 1000
        repeat: true
        running: root.usageLoaded
        onTriggered: root.recordSecond()
    }

    Timer {
        id: saveTimer
        interval: 300
        repeat: false
        onTriggered: root.flushUsage()
    }

    Process {
        id: idleWatcher
        command: [
            "swayidle", "-w",
            "timeout", "60", "qs ipc call screen-time idle",
            "resume", "qs ipc call screen-time resume"
        ]
        running: true

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim()
                if (message.length)
                    console.warn("A16EEN screen-time idle watcher:", message)
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.idle = false
            if (exitCode !== 0)
                console.warn("A16EEN screen-time idle watcher exited with status", exitCode)
            idleWatcherRestart.start()
        }
    }

    Timer {
        id: idleWatcherRestart
        interval: 5000
        repeat: false
        onTriggered: idleWatcher.running = true
    }

    onLockedChanged: {
        root.lastSampleMs = 0
        root.pendingActiveMs = 0
        if (root.locked)
            saveTimer.restart()
    }

    Component.onDestruction: root.flushUsage()
}
