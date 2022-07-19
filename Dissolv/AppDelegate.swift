//
//  AppDelegate.swift
//  Dissolv
//
//  Created by Tomislav Filipcic on 19.07.2022..
//

import Cocoa
import OSLog
import Preferences

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
                    let timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timerFire), userInfo: ["app": currentApp], repeats: false)
                    watchedApplication.timer?.invalidate()
                    watchedApplication.timer = timer
                    logger.debug("\(currentApp.localizedName ?? "", privacy: .public) scheduled timer")
                }
                
                currentApp.addObserver(self, forKeyPath: "isActive", options: .new, context: nil)
                currentApp.addObserver(self, forKeyPath: "isTerminated", options: .new, context: nil)
//                currentApp.hide()
            }
        }
        
        ws.addObserver(self, forKeyPath: "runningApplications", options: .new, context: nil)
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
                            let timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timerFire), userInfo: ["app": runningApp], repeats: false)
                            watchedApplication.timer?.invalidate()
                            watchedApplication.timer = timer
                            logger.debug("\(runningApp.localizedName ?? "", privacy: .public) scheduled timer")
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
                    let timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timerFire), userInfo: ["app": app], repeats: false)
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

        if (!app.isHidden && !app.isActive) {
            logger.debug("\(app.localizedName ?? "", privacy: .public) hiding")
            app.hide()
        }
    }
}
