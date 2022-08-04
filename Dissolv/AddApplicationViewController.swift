//
//  AddApplicationViewController.swift
//  Dissolv
//

import Cocoa
import Defaults

protocol AddApplicationDelegate: AnyObject {
    func didSelectApplications(apps: [String], controller: AddApplicationViewController)
}

class AddApplicationViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableView: NSTableView!
    private var apps: [String] = []
    private var selectedApps: [String] = []
    weak var delegate: AddApplicationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ws = NSWorkspace.shared
        for app in ws.runningApplications {
            // TODO: Check if already in list
            if (app.activationPolicy == .regular) {
                if let name = app.localizedName {
                    let customAppSettings = Defaults[.customAppSettings]
                    if !customAppSettings.contains(where: { $0.appName == name }) {
                        apps.append(name)
                    }
                }
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.styleMask.remove(.resizable)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return apps.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let app = apps[row]
        
        if selectedApps.contains(app) {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        if let cell = cell as? NSButtonCell {
            cell.title = apps[row]
        }
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if let checked = object as? Bool {
            if checked {
                selectedApps.append(apps[row])
            } else {
                selectedApps = selectedApps.filter { $0 != apps[row] }
            }
        }
        
        tableView.reloadData()
    }
    
    @IBAction func donePress(_ sender: Any) {
        delegate?.didSelectApplications(apps: selectedApps, controller: self)
    }
}
