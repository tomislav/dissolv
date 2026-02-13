//
//  AppDelegate.swift
//  Dissolv
//
//  Created by Tomislav Filipcic on 19.07.2022..
//

import Cocoa
import OSLog
import Preferences
import Defaults
import KeyboardShortcuts

extension Settings.PaneIdentifier {
    static let general = Self("general")
    static let advanced = Self("advanced")
    static let about = Self("about")
}

final class WatchedApplication {
    let app: NSRunningApplication
    var timer: Timer?
    var isActiveObservation: NSKeyValueObservation?
    var isTerminatedObservation: NSKeyValueObservation?

    init(app: NSRunningApplication) {
        self.app = app
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil

        isActiveObservation?.invalidate()
        isActiveObservation = nil

        isTerminatedObservation?.invalidate()
        isTerminatedObservation = nil
    }
}

//@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var watchedApplications: [pid_t: WatchedApplication] = [:]
    private var isPaused = false
    private var pauseMenuItem: NSMenuItem?
    private var settingsWindowController: SettingsWindowController?
    private var workspaceObservers: [NSObjectProtocol] = []

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.7sols.Dissolv",
        category: "Main"
    )

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        logger.info("Dissolv v\(version) (\(build)) starting")

        if Defaults[.firstRunDate] == nil {
            Defaults[.firstRunDate] = Date()
        }

        setupStatusItem()

        KeyboardShortcuts.onKeyUp(for: .togglePause) { [weak self] in
            self?.pause()
        }

        setupMenus()
        observeWorkspaceApplications()

        for runningApp in NSWorkspace.shared.runningApplications {
            beginWatchingApplicationIfNeeded(runningApp)
        }

        migrateLegacyCustomSettings()

        _ = Defaults.observe(.hideAfter, options: []) { [weak self] _ in
            self?.rescheduleVisibleInactiveApps()
        }.tieToLifetime(of: self)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidUpdateAppSetting(_:)),
            name: .userDidUpdateAppSetting,
            object: nil
        )

        if !Defaults[.showSettingsOnFirstStart] {
            showSettings()
            Defaults[.showSettingsOnFirstStart] = true
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        teardownObservers()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    @objc private func didTapPreferences() {
        showSettings()
    }

    @objc private func didTapAbout() {
        showSettings(preferencePane: .about)
    }

    @objc private func didTapPause() {
        pause()
    }

    @objc private func didTapBuy() {
        guard let url = URL(string: "https://apps.apple.com/app/dissolv/id1640893012") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    @objc private func userDidUpdateAppSetting(_ notification: Notification) {
        let appIdentifier = notification.userInfo?["appIdentifier"] as? String
        let appName = notification.userInfo?["appName"] as? String

        for watched in watchedApplications.values {
            if let appIdentifier, watched.app.bundleIdentifier == appIdentifier {
                watched.timer?.invalidate()
                watched.timer = nil
                if !watched.app.isHidden && !watched.app.isActive {
                    scheduleTimer(for: watched)
                }
                continue
            }

            if let appName, watched.app.localizedName == appName {
                watched.timer?.invalidate()
                watched.timer = nil
                if !watched.app.isHidden && !watched.app.isActive {
                    scheduleTimer(for: watched)
                }
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon()
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else {
            return
        }

        let imageName = isPaused ? "menubar-icon-paused" : "menubar-icon"
        let image = NSImage(named: imageName)
        image?.isTemplate = true
        button.image = image
    }

    private func setupMenus() {
        let menu = NSMenu()

        let pauseItem = NSMenuItem(title: "Pause hiding", action: #selector(didTapPause), keyEquivalent: "")
        pauseItem.setShortcut(for: .togglePause)
        pauseMenuItem = pauseItem
        menu.addItem(pauseItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "About Dissolv", action: #selector(didTapAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(didTapPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func showSettings(preferencePane: Settings.PaneIdentifier? = nil) {
        settingsWindowController?.close()
        settingsWindowController = SettingsWindowController(
            panes: [
                Settings.Pane(
                    identifier: .general,
                    title: "General",
                    toolbarIcon: NSImage(
                        systemSymbolName: "gearshape",
                        accessibilityDescription: "General settings"
                    )!
                ) {
                    GeneralSettingsView()
                },
                Settings.Pane(
                    identifier: .advanced,
                    title: "Advanced",
                    toolbarIcon: NSImage(
                        systemSymbolName: "macwindow.badge.plus",
                        accessibilityDescription: "Advanced settings"
                    )!
                ) {
                    AdvancedSettingsView()
                },
                Settings.Pane(
                    identifier: .about,
                    title: "About",
                    toolbarIcon: NSImage(
                        systemSymbolName: "macwindow.on.rectangle",
                        accessibilityDescription: "About the application"
                    )!
                ) {
                    AboutSettingsView()
                },
            ],
            animated: false
        )

        if let preferencePane {
            settingsWindowController?.show(preferencePane: preferencePane)
        } else {
            settingsWindowController?.show()
        }
    }

    private func pause() {
        isPaused.toggle()
        pauseMenuItem?.title = isPaused ? "Resume hiding" : "Pause hiding"
        updateStatusIcon()

        if !isPaused {
            rescheduleVisibleInactiveApps()
        }
    }

    private func observeWorkspaceApplications() {
        let center = NSWorkspace.shared.notificationCenter

        workspaceObservers.append(
            center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                    return
                }

                self?.beginWatchingApplicationIfNeeded(app)
            }
        )

        workspaceObservers.append(
            center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                    return
                }

                self?.removeWatchedApplication(forProcessIdentifier: app.processIdentifier)
            }
        )

        workspaceObservers.append(
            center.addObserver(forName: NSWorkspace.didHideApplicationNotification, object: nil, queue: .main) { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                    return
                }

                self?.watchedApplications[app.processIdentifier]?.timer?.invalidate()
                self?.watchedApplications[app.processIdentifier]?.timer = nil
            }
        )

        workspaceObservers.append(
            center.addObserver(forName: NSWorkspace.didUnhideApplicationNotification, object: nil, queue: .main) { [weak self] notification in
                guard
                    let self,
                    let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                else {
                    return
                }

                self.beginWatchingApplicationIfNeeded(app)
                if !app.isActive {
                    self.scheduleTimerIfNeeded(forProcessIdentifier: app.processIdentifier)
                }
            }
        )
    }

    private func beginWatchingApplicationIfNeeded(_ app: NSRunningApplication) {
        guard app.activationPolicy == .regular else {
            return
        }

        let processIdentifier = app.processIdentifier
        guard watchedApplications[processIdentifier] == nil else {
            return
        }

        let watched = WatchedApplication(app: app)
        watchedApplications[processIdentifier] = watched

        watched.isActiveObservation = app.observe(\.isActive, options: [.new]) { [weak self] app, _ in
            self?.handleActiveStateChange(for: app)
        }

        watched.isTerminatedObservation = app.observe(\.isTerminated, options: [.new]) { [weak self] app, _ in
            guard app.isTerminated else {
                return
            }

            self?.removeWatchedApplication(forProcessIdentifier: app.processIdentifier)
        }

        updateCustomSettingDisplayNameIfNeeded(for: app)

        if !app.isHidden && !app.isActive {
            scheduleTimer(for: watched)
        }

        logger.info("Observing \(app.localizedName ?? "", privacy: .public)")
    }

    private func removeWatchedApplication(forProcessIdentifier processIdentifier: pid_t) {
        guard let watched = watchedApplications[processIdentifier] else {
            return
        }

        watched.invalidate()
        watchedApplications.removeValue(forKey: processIdentifier)
        logger.info("\(watched.app.localizedName ?? "", privacy: .public) terminated")
    }

    private func handleActiveStateChange(for app: NSRunningApplication) {
        guard let watched = watchedApplications[app.processIdentifier] else {
            return
        }

        if app.isActive {
            watched.timer?.invalidate()
            watched.timer = nil
            logger.info("\(app.localizedName ?? "", privacy: .public) is active")
            return
        }

        logger.info("\(app.localizedName ?? "", privacy: .public) is not active")
        if !app.isHidden {
            scheduleTimer(for: watched)
        }
    }

    private func scheduleTimerIfNeeded(forProcessIdentifier processIdentifier: pid_t) {
        guard let watched = watchedApplications[processIdentifier] else {
            return
        }

        scheduleTimer(for: watched)
    }

    private func scheduleTimer(for watched: WatchedApplication) {
        let app = watched.app

        if shouldSuppressHiding(for: app) {
            watched.timer?.invalidate()
            watched.timer = nil
            return
        }

        let hideAfterSeconds = hideAfter(for: app)
        guard hideAfterSeconds > 0 else {
            watched.timer?.invalidate()
            watched.timer = nil
            return
        }

        watched.timer?.invalidate()
        watched.timer = Timer.scheduledTimer(withTimeInterval: hideAfterSeconds, repeats: false) { [weak self, weak app] _ in
            guard let self, let app else {
                return
            }

            self.handleTimerFire(forProcessIdentifier: app.processIdentifier)
        }

        logger.info("Scheduled timer for \(app.localizedName ?? "", privacy: .public): \(Int(hideAfterSeconds)) seconds")
    }

    private func handleTimerFire(forProcessIdentifier processIdentifier: pid_t) {
        if isPaused {
            return
        }

        guard let watched = watchedApplications[processIdentifier] else {
            return
        }

        let app = watched.app
        logger.debug("\(app.localizedName ?? "", privacy: .public) timer fired")

        if !app.isHidden && !app.isActive {
            logger.info("\(app.localizedName ?? "", privacy: .public) hiding")
            app.hide()
        }
    }

    private func rescheduleVisibleInactiveApps() {
        for watched in watchedApplications.values where !watched.app.isHidden && !watched.app.isActive {
            scheduleTimer(for: watched)
        }
    }

    private func hideAfter(for app: NSRunningApplication?) -> Double {
        guard let app else {
            return Defaults[.hideAfter]
        }

        let identity = AppIdentity(bundleIdentifier: app.bundleIdentifier, localizedName: app.localizedName)
        return AppSettingsResolver.hideAfter(
            for: identity,
            settings: Defaults[.customAppSettings],
            defaultHideAfter: Defaults[.hideAfter]
        )
    }

    private func shouldSuppressHiding(for app: NSRunningApplication) -> Bool {
        return hideAfter(for: app) == 0
    }

    private func updateCustomSettingDisplayNameIfNeeded(for app: NSRunningApplication) {
        guard
            let bundleIdentifier = app.bundleIdentifier,
            let localizedName = app.localizedName
        else {
            return
        }

        var settings = Defaults[.customAppSettings]
        guard let index = settings.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return
        }

        if settings[index].appName != localizedName {
            settings[index].appName = localizedName
            Defaults[.customAppSettings] = settings
        }
    }

    private func migrateLegacyCustomSettings() {
        var settings = Defaults[.customAppSettings]
        var didChange = false
        let runningApps = NSWorkspace.shared.runningApplications

        for index in settings.indices {
            let setting = settings[index]
            guard setting.bundleIdentifier == setting.appName else {
                continue
            }

            guard
                let runningApp = runningApps.first(where: { $0.localizedName == setting.appName }),
                let bundleIdentifier = runningApp.bundleIdentifier
            else {
                continue
            }

            settings[index].bundleIdentifier = bundleIdentifier
            didChange = true
        }

        if didChange {
            Defaults[.customAppSettings] = settings
        }
    }

    private func teardownObservers() {
        NotificationCenter.default.removeObserver(self, name: .userDidUpdateAppSetting, object: nil)

        let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers {
            workspaceNotificationCenter.removeObserver(observer)
        }
        workspaceObservers.removeAll()

        for watched in watchedApplications.values {
            watched.invalidate()
        }
        watchedApplications.removeAll()
    }
}
