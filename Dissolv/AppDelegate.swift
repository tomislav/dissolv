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

extension Settings.PaneIdentifier {
    static let general = Self("general")
    static let advanced = Self("advanced")
}

class WatchedApplication {
    var app: NSRunningApplication!
    var timer: Timer?
}

//@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var watchedApplications: [WatchedApplication] = []

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Main"
    )
    
    private lazy var settingsWindowController = SettingsWindowController(
        preferencePanes: [
            GeneralSettingsViewController(),
            AdvancedSettingsViewController()
        ]
    )
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        logger.info("Dissolv starting")
        
        // 2
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // 3
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "dissolve")
        }

        setupMenus()
        
        let ws = NSWorkspace.shared
        let apps = ws.runningApplications
        for currentApp in apps
        {
            if (currentApp.activationPolicy == .regular) {
                let watchedApplication = WatchedApplication()
                watchedApplication.app = currentApp
                watchedApplications.append(watchedApplication)
                
                if !currentApp.isHidden {
                    scheduleTimer(for: currentApp, watched: watchedApplication)
                }
                
                currentApp.addObserver(self, forKeyPath: "isActive", options: .new, context: nil)
                currentApp.addObserver(self, forKeyPath: "isTerminated", options: .new, context: nil)
//                currentApp.hide()
            }
        }
        
        ws.addObserver(self, forKeyPath: "runningApplications", options: .new, context: nil)
        
        let _ = Defaults.observe(.hideAfter, options: []) { change in
            for app in self.watchedApplications {
                if !app.app.isHidden {
                    self.scheduleTimer(for: app.app, watched: app)
                }
            }
        }.tieToLifetime(of: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidUpdateAppSetting), name: .userDidUpdateAppSetting, object: nil)
    }
    
    func scheduleTimer(for app: NSRunningApplication, watched: WatchedApplication) {
        if let appSettings = Defaults[.customAppSettings].filter({ $0.appName == app.localizedName }).first {
            if appSettings.hideAfter == 0 {
                return
            }
        }
        
        let timer = Timer.scheduledTimer(timeInterval: hideAfter(app: app), target: self, selector: #selector(timerFire), userInfo: ["app": app], repeats: false)
        watched.timer?.invalidate()
        watched.timer = timer
        logger.debug("\(app.localizedName ?? "", privacy: .public) scheduled timer")
    }
    
    func setupMenus() {
        let menu = NSMenu()

        let one = NSMenuItem(title: "Preferences...", action: #selector(didTapPreferences) , keyEquivalent: ",")
        menu.addItem(one)

        menu.addItem(NSMenuItem.separator())

        let two = NSMenuItem(title: "About Dissolv", action: #selector(didTapAbout) , keyEquivalent: "")
        menu.addItem(two)

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc func didTapPreferences() {
//        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController.show()
    }

    @objc func didTapAbout() {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "runningApplications" {
            // Find new
            for runningApp in NSWorkspace.shared.runningApplications {
                if (runningApp.activationPolicy == .regular) {
                    var found: Bool = false
                    for watchedApp in watchedApplications {
                        if watchedApp.app == runningApp {
                            found = true
                        }
                    }
                    
                    if !found {
                        let watchedApplication = WatchedApplication()
                        watchedApplication.app = runningApp
                        watchedApplications.append(watchedApplication)
                        
                        if !runningApp.isHidden {
                            scheduleTimer(for: runningApp, watched: watchedApplication)
                        }
                        
                        runningApp.addObserver(self, forKeyPath: "isActive", options: .new, context: nil)
                        runningApp.addObserver(self, forKeyPath: "isTerminated", options: .new, context: nil)

                        logger.debug("\(runningApp.localizedName ?? "", privacy: .public) watched")
                    }
                }
            }
        } else if keyPath == "isActive" {
            let app = object as! NSRunningApplication
            if app.isActive {
                let app = object as! NSRunningApplication
                
                logger.debug("\(app.localizedName ?? "", privacy: .public) is active")

                if let index = watchedApplications.firstIndex(where: {$0.app == app}) {
                    watchedApplications[index].timer?.invalidate()
                    logger.debug("\(app.localizedName ?? "", privacy: .public) invalidated timer")
                }
            } else {
                logger.debug("\(app.localizedName ?? "", privacy: .public) is not active")
                if !app.isHidden {
                    if let appSettings = Defaults[.customAppSettings].filter({ $0.appName == app.localizedName }).first {
                        if appSettings.hideAfter == 0 {
                            return
                        }
                    }
                    
                    let timer = Timer.scheduledTimer(timeInterval: hideAfter(app: app), target: self, selector: #selector(timerFire), userInfo: ["app": app], repeats: false)
                    if let index = watchedApplications.firstIndex(where: {$0.app == app}) {
                        watchedApplications[index].timer?.invalidate()
                        watchedApplications[index].timer = timer
                        logger.debug("\(app.localizedName ?? "", privacy: .public) scheduled timer")
                    }
                }
            }
        } else if keyPath == "isTerminated" {
            let app = object as! NSRunningApplication

            if app.isTerminated {
                app.removeObserver(self, forKeyPath: "isTerminated")
                app.removeObserver(self, forKeyPath: "isActive")
                if let watchedApp = watchedApplications.filter({ $0.app == app }).first {
                    watchedApp.timer?.invalidate()
                }

                watchedApplications = watchedApplications.filter { $0.app != app }
                
                logger.debug("\(app.localizedName ?? "", privacy: .public) terminated")
            }
        }
    }
    
    @objc func timerFire(timer:Timer) {
        let userInfo = timer.userInfo as! Dictionary<String, AnyObject>
        
        let app = userInfo["app"] as! NSRunningApplication
        logger.debug("\(app.localizedName ?? "", privacy: .public) timer fired")

        if let appSettings = Defaults[.customAppSettings].filter({ $0.appName == app.localizedName }).first {
            if appSettings.action == .quit && !app.isActive {
                logger.debug("\(app.localizedName ?? "", privacy: .public) quiting")
                app.terminate()
                return
            }
        }
        
        if (!app.isHidden && !app.isActive) {
            logger.debug("\(app.localizedName ?? "", privacy: .public) hiding")
            app.hide()
        }
    }
    
    @objc func userDidUpdateAppSetting(_ notification: Notification) {
        guard let appName = notification.userInfo?["appName"] as? String else { return }
        
        for app in watchedApplications {
            if app.app.localizedName == appName {
                app.timer?.invalidate()
                app.timer = nil
            }
        }
    }
    
    private func hideAfter(app: NSRunningApplication?) -> Double {
        if let app = app, let appSettings = Defaults[.customAppSettings].filter({ $0.appName == app.localizedName }).first {
            return appSettings.hideAfter
        }
        
        return Defaults[.hideAfter]
    }
}
