//
//  AboutViewController.swift
//  Dissolv
//

import Cocoa
import Preferences

class AboutViewController: NSViewController, SettingsPane {
    @IBOutlet weak var versionLabel: NSTextField!
    
    let preferencePaneIdentifier = Settings.PaneIdentifier.about
    let preferencePaneTitle = "About"
    let toolbarItemIcon = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "About the application")!

    override var nibName: NSNib.Name? { "AboutViewController" }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        
        versionLabel.stringValue = "v\(version) (\(build))"
    }
    
    @IBAction func contactUsPress(_ sender: Any) {
        let url = URL(string:"mailto:support+dissolv@7sols.com")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func websitePress(_ sender: Any) {
        let url = URL(string:"https://www.7sols.com/dissolv")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func acknowledgementsPress(_ sender: Any) {
    }
}
