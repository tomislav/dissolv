import Cocoa
import Preferences
import OSLog
import Defaults
import LaunchAtLogin

final class GeneralSettingsViewController: NSViewController, SettingsPane {
    @IBOutlet weak var hideAfterLabel: NSTextField!
    @IBOutlet weak var hideAfterSlider: NSSlider!
    @IBOutlet weak var launchAtLoginButton: NSButton!
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "General Settings"
    )
    
    let preferencePaneIdentifier = Settings.PaneIdentifier.general
	let preferencePaneTitle = "General"
	let toolbarItemIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General settings")!

	override var nibName: NSNib.Name? { "GeneralSettingsViewController" }

	override func viewDidLoad() {
		super.viewDidLoad()

        hideAfterSlider.isContinuous = true
        
        if LaunchAtLogin.isEnabled {
            launchAtLoginButton.state = .on
        }
        
        switch Defaults[.hideAfter] {
        case 0:
            hideAfterLabel.stringValue = "Never"
            hideAfterSlider.doubleValue = 100
        case 30:
            hideAfterLabel.stringValue = "30 seconds"
            hideAfterSlider.doubleValue = 0
        case 60:
            hideAfterLabel.stringValue = "1 minute"
            hideAfterSlider.doubleValue = 0.75
        case 120:
            hideAfterLabel.stringValue = "2 minutes"
            hideAfterSlider.doubleValue = 1.5
        case 180:
            hideAfterLabel.stringValue = "3 minutes"
            hideAfterSlider.doubleValue = 2.5
        case 240:
            hideAfterLabel.stringValue = "4 minutes"
            hideAfterSlider.doubleValue = 3.5
        case 300:
            hideAfterLabel.stringValue = "5 minutes"
            hideAfterSlider.doubleValue = 5
        case 600:
            hideAfterLabel.stringValue = "10 minutes"
            hideAfterSlider.doubleValue = 7
        case 900:
            hideAfterLabel.stringValue = "15 minutes"
            hideAfterSlider.doubleValue = 10
        case 1200:
            hideAfterLabel.stringValue = "20 minutes"
            hideAfterSlider.doubleValue = 13.5
        case 1500:
            hideAfterLabel.stringValue = "25 minutes"
            hideAfterSlider.doubleValue = 16.25
        case 1800:
            hideAfterLabel.stringValue = "30 minutes"
            hideAfterSlider.doubleValue = 20
        case 35 * 60:
            hideAfterLabel.stringValue = "35 minutes"
            hideAfterSlider.doubleValue = 23.75
        case 40 * 60:
            hideAfterLabel.stringValue = "40 minutes"
            hideAfterSlider.doubleValue = 26.25
        case 45 * 60:
            hideAfterLabel.stringValue = "45 minutes"
            hideAfterSlider.doubleValue = 30
        case 50 * 60:
            hideAfterLabel.stringValue = "50 minutes"
            hideAfterSlider.doubleValue = 33.75
        case 55 * 60:
            hideAfterLabel.stringValue = "55 minutes"
            hideAfterSlider.doubleValue = 36.25
        case 60 * 60:
            hideAfterLabel.stringValue = "1 hour"
            hideAfterSlider.doubleValue = 40
        case 2 * 60 * 60:
            hideAfterLabel.stringValue = "2 hours"
            hideAfterSlider.doubleValue = 50
        case 3 * 60 * 60:
            hideAfterLabel.stringValue = "3 hours"
            hideAfterSlider.doubleValue = 60
        case 4 * 60 * 60:
            hideAfterLabel.stringValue = "4 hours"
            hideAfterSlider.doubleValue = 70
        case 5 * 60 * 60:
            hideAfterLabel.stringValue = "5 hours"
            hideAfterSlider.doubleValue = 80
        case 6 * 60 * 60:
            hideAfterLabel.stringValue = "6 hours"
            hideAfterSlider.doubleValue = 90
        default:
            hideAfterLabel.stringValue = "Unknown"
        }
	}
    
    @IBAction func sliderDidChange(_ sender: NSSlider) {
//        logger.debug("Slider did change to \(sender.doubleValue)")
        let value = sender.doubleValue
        
        if value >= 0 && value <= 0.5 {
            hideAfterLabel.stringValue = "30 seconds"
            sender.doubleValue = 0
            Defaults[.hideAfter] = 30
        } else if value > 0.5 && value <= 1 {
            hideAfterLabel.stringValue = "1 minute"
            sender.doubleValue = 0.75
            Defaults[.hideAfter] = 60
        } else if value > 1 && value <= 2 {
            hideAfterLabel.stringValue = "2 minutes"
            sender.doubleValue = 1.5
            Defaults[.hideAfter] = 120
        } else if value > 2 && value <= 3 {
            hideAfterLabel.stringValue = "3 minutes"
            sender.doubleValue = 2.5
            Defaults[.hideAfter] = 180
        } else if value > 3 && value <= 4 {
            hideAfterLabel.stringValue = "4 minutes"
            sender.doubleValue = 3.5
            Defaults[.hideAfter] = 240
        } else if value > 4 && value <= 6 {
            hideAfterLabel.stringValue = "5 minutes"
            sender.doubleValue = 5
            Defaults[.hideAfter] = 300
        } else if value > 6 && value <= 8 {
            hideAfterLabel.stringValue = "10 minutes"
            sender.doubleValue = 7
            Defaults[.hideAfter] = 600
        } else if value > 8 && value <= 12 {
            hideAfterLabel.stringValue = "15 minutes"
            sender.doubleValue = 10
            Defaults[.hideAfter] = 900
        } else if value > 12 && value <= 15 {
            hideAfterLabel.stringValue = "20 minutes"
            sender.doubleValue = 13.5
            Defaults[.hideAfter] = 1200
        } else if value > 15 && value <= 17.5 {
            hideAfterLabel.stringValue = "25 minutes"
            sender.doubleValue = 16.25
            Defaults[.hideAfter] = 1500
        } else if value > 17.5 && value <= 22.5 {
            hideAfterLabel.stringValue = "30 minutes"
            sender.doubleValue = 20
            Defaults[.hideAfter] = 1800
        } else if value > 22.5 && value <= 25 {
            hideAfterLabel.stringValue = "35 minutes"
            sender.doubleValue = 23.75
            Defaults[.hideAfter] = 35 * 60
        } else if value > 25 && value <= 27.5 {
            hideAfterLabel.stringValue = "40 minutes"
            sender.doubleValue = 26.25
            Defaults[.hideAfter] = 40 * 60
        } else if value > 27.5 && value <= 32.5 {
            hideAfterLabel.stringValue = "45 minutes"
            sender.doubleValue = 30
            Defaults[.hideAfter] = 45 * 60
        } else if value > 32.5 && value <= 35 {
            hideAfterLabel.stringValue = "50 minutes"
            sender.doubleValue = 33.75
            Defaults[.hideAfter] = 50 * 60
        } else if value > 35 && value <= 37.5 {
            hideAfterLabel.stringValue = "55 minutes"
            sender.doubleValue = 36.25
            Defaults[.hideAfter] = 55 * 60
        } else if value > 37.5 && value <= 45 {
            hideAfterLabel.stringValue = "1 hour"
            sender.doubleValue = 40
            Defaults[.hideAfter] = 60 * 60
        } else if value > 45 && value <= 55 {
            hideAfterLabel.stringValue = "2 hours"
            sender.doubleValue = 50
            Defaults[.hideAfter] = 2 * 60 * 60
        } else if value > 55 && value <= 65 {
            hideAfterLabel.stringValue = "3 hours"
            sender.doubleValue = 60
            Defaults[.hideAfter] = 3 * 60 * 60
        } else if value > 65 && value <= 75 {
            hideAfterLabel.stringValue = "4 hours"
            sender.doubleValue = 70
            Defaults[.hideAfter] = 4 * 60 * 60
        } else if value > 75 && value <= 85 {
            hideAfterLabel.stringValue = "5 hours"
            sender.doubleValue = 80
            Defaults[.hideAfter] = 5 * 60 * 60
        } else if value > 85 && value <= 95 {
            hideAfterLabel.stringValue = "6 hours"
            sender.doubleValue = 90
            Defaults[.hideAfter] = 6 * 60 * 60
        } else if value > 95 && value <= 100 {
            hideAfterLabel.stringValue = "Never"
            sender.doubleValue = 100
            Defaults[.hideAfter] = 0
        }
    }
    
    @IBAction func launchAtLoginPressed(_ sender: Any) {
        logger.debug("Launch at login pressed")
        
        if launchAtLoginButton.state == .on {
            LaunchAtLogin.isEnabled = true
        } else {
            LaunchAtLogin.isEnabled = false
        }
    }
    
}
