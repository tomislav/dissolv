import Cocoa
import Preferences
import OSLog
import Defaults

final class AdvancedSettingsViewController: NSViewController, SettingsPane, AddApplicationDelegate, NSCollectionViewDelegate, NSCollectionViewDataSource {
	let preferencePaneIdentifier = Settings.PaneIdentifier.advanced
	let preferencePaneTitle = "Advanced"
	let toolbarItemIcon = NSImage(systemSymbolName: "macwindow.badge.plus", accessibilityDescription: "Advanced settings")!

    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var actionPopupButton: NSPopUpButton!
    @IBOutlet weak var hideAfterLabel: NSTextField!
    @IBOutlet weak var hideAfterSlider: NSSlider!
    @IBOutlet weak var ctaBox: NSBox!
    @IBOutlet weak var mainBox: NSBox!
    
    override var nibName: NSNib.Name? { "AdvancedSettingsViewController" }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Advanced Settings"
    )
    
	override func viewDidLoad() {
		super.viewDidLoad()

        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 178.0, height: 56)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 10.0, bottom: 0.0, right: 10.0)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = flowLayout
        collectionView.register(AppCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "App"))
        
        hideAfterSlider.isContinuous = true
        
        if Defaults[.customAppSettings].count > 0 {
            if let customAppSetting = Defaults[.customAppSettings].first {
                collectionView.selectItems(at: [IndexPath(item: 0, section: 0)], scrollPosition: .top)
                updateSettingsPanel(with: customAppSetting)
            }
        } else {
            ctaBox.isHidden = false
            mainBox.isHidden = true
        }
	}
    
    @IBAction func segmentedControlPress(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            let controller = AddApplicationViewController()
            controller.delegate = self
            self.presentAsSheet(controller)
        } else if sender.selectedSegment == 1 {
            if let selectedItem = collectionView.selectionIndexes.first {
                let appName = Defaults[.customAppSettings][selectedItem].appName
                
                var indexPaths: Set<IndexPath> = []
                Defaults[.customAppSettings].remove(at: selectedItem)
                let currentIndexPath = IndexPath(item: selectedItem, section: 0)
                indexPaths.insert(currentIndexPath)
                collectionView.deleteItems(at: indexPaths)
                
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": appName])
                
                if Defaults[.customAppSettings].count > 0 {
                    ctaBox.isHidden = true
                    mainBox.isHidden = false
                    
                    var indexToSelect = 0
                    if selectedItem > 0 {
                        indexToSelect = selectedItem - 1
                    }
                    collectionView.selectItems(at: [IndexPath(item: indexToSelect, section: 0)], scrollPosition: .centeredVertically)
                    updateSettingsPanel(with: Defaults[.customAppSettings][indexToSelect])
                } else {
                    ctaBox.isHidden = false
                    mainBox.isHidden = true
                }
            } else {
                ctaBox.isHidden = false
                mainBox.isHidden = true
            }
        }
    }
    
    @IBAction func addApplicationsButtonPress(_ sender: Any) {
        let controller = AddApplicationViewController()
        controller.delegate = self
        self.presentAsSheet(controller)
    }
    
    func didSelectApplications(apps: [String], controller: AddApplicationViewController) {
        guard apps.count > 0 else { return }
        
        collectionView.deselectItems(at: collectionView.selectionIndexPaths)
        
        var indexPaths: Set<IndexPath> = []
        
        ctaBox.isHidden = true
        mainBox.isHidden = false
        
        for app in apps {
            let settings = CustomAppSetting(appName: app, hideAfter: Defaults[.hideAfter], action: .hide)
            Defaults[.customAppSettings].append(settings)
            let currentIndexPath = IndexPath(item: Defaults[.customAppSettings].count - 1, section: 0)
            indexPaths.insert(currentIndexPath)
        }
        
        collectionView.insertItems(at: indexPaths)
        
        if let firstIndexPath = indexPaths.first {
            collectionView.selectItems(at: [IndexPath(item: firstIndexPath.item, section: 0)], scrollPosition: .centeredVertically)
            updateSettingsPanel(with: Defaults[.customAppSettings][firstIndexPath.item])
        }
        
        self.dismiss(controller)
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return Defaults[.customAppSettings].count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "App"), for: indexPath) as! AppCollectionViewItem
        let setting = Defaults[.customAppSettings][indexPath.item]
        item.label1.stringValue = setting.appName
        item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first
            else { return }
        guard let item = collectionView.item(at: indexPath)
            else { return }
        item.isSelected = true
        
        let appSetting = Defaults[.customAppSettings][indexPath.item]
        updateSettingsPanel(with: appSetting)
    }
    
    func updateSettingsPanel(with item: CustomAppSetting) {
        titleLabel.stringValue = item.appName
        if item.action == .hide {
            actionPopupButton.selectItem(at: 0)
        } else {
            actionPopupButton.selectItem(at: 1)
        }
        
        hideAfterLabel.stringValue = timeLabelFor(hideAfter: item.hideAfter)
        
        switch item.hideAfter {
        case 0:
            hideAfterSlider.doubleValue = 100
        case 30:
            hideAfterSlider.doubleValue = 0
        case 60:
            hideAfterSlider.doubleValue = 0.75
        case 120:
            hideAfterSlider.doubleValue = 1.5
        case 180:
            hideAfterSlider.doubleValue = 2.5
        case 240:
            hideAfterSlider.doubleValue = 3.5
        case 300:
            hideAfterSlider.doubleValue = 5
        case 600:
            hideAfterSlider.doubleValue = 7
        case 900:
            hideAfterSlider.doubleValue = 10
        case 1200:
            hideAfterSlider.doubleValue = 13.5
        case 1500:
            hideAfterSlider.doubleValue = 16.25
        case 1800:
            hideAfterSlider.doubleValue = 20
        case 35 * 60:
            hideAfterSlider.doubleValue = 23.75
        case 40 * 60:
            hideAfterSlider.doubleValue = 26.25
        case 45 * 60:
            hideAfterSlider.doubleValue = 30
        case 50 * 60:
            hideAfterSlider.doubleValue = 33.75
        case 55 * 60:
            hideAfterSlider.doubleValue = 36.25
        case 60 * 60:
            hideAfterSlider.doubleValue = 40
        case 2 * 60 * 60:
            hideAfterSlider.doubleValue = 50
        case 3 * 60 * 60:
            hideAfterSlider.doubleValue = 60
        case 4 * 60 * 60:
            hideAfterSlider.doubleValue = 70
        case 5 * 60 * 60:
            hideAfterSlider.doubleValue = 80
        case 6 * 60 * 60:
            hideAfterSlider.doubleValue = 90
        default:
            break
        }
    }
    
    func timeLabelFor(hideAfter: Double) -> String {
        switch hideAfter {
        case 0:
            return "Never"
        case 30:
            return "30 seconds"
        case 60:
            return "1 minute"
        case 120:
            return "2 minutes"
        case 180:
            return "3 minutes"
        case 240:
            return "4 minutes"
        case 300:
            return "5 minutes"
        case 600:
            return "10 minutes"
        case 900:
            return "15 minutes"
        case 1200:
            return "20 minutes"
        case 1500:
            return "25 minutes"
        case 1800:
            return "30 minutes"
        case 35 * 60:
            return "35 minutes"
        case 40 * 60:
            return "40 minutes"
        case 45 * 60:
            return "45 minutes"
        case 50 * 60:
            return "50 minutes"
        case 55 * 60:
            return "55 minutes"
        case 60 * 60:
            return "1 hour"
        case 2 * 60 * 60:
            return "2 hours"
        case 3 * 60 * 60:
            return "3 hours"
        case 4 * 60 * 60:
            return "4 hours"
        case 5 * 60 * 60:
            return "5 hours"
        case 6 * 60 * 60:
            return "6 hours"
        default:
            return "Unknown"
        }
    }
    
    @IBAction func sliderDidChange(_ sender: NSSlider) {
//        logger.debug("Slider did change to \(sender.doubleValue)")
        let value = sender.doubleValue
        guard let selectedItem = collectionView.selectionIndexes.first else { return }
        
        if value >= 0 && value <= 0.5 {
            hideAfterLabel.stringValue = "30 seconds"
            sender.doubleValue = 0
            if Defaults[.customAppSettings][selectedItem].hideAfter != 30 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 30
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 0.5 && value <= 1 {
            hideAfterLabel.stringValue = "1 minute"
            sender.doubleValue = 0.75
            if Defaults[.customAppSettings][selectedItem].hideAfter != 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 1 && value <= 2 {
            hideAfterLabel.stringValue = "2 minutes"
            sender.doubleValue = 1.5
            if Defaults[.customAppSettings][selectedItem].hideAfter != 120 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 120
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 2 && value <= 3 {
            hideAfterLabel.stringValue = "3 minutes"
            sender.doubleValue = 2.5
            if Defaults[.customAppSettings][selectedItem].hideAfter != 180 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 180
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 3 && value <= 4 {
            hideAfterLabel.stringValue = "4 minutes"
            sender.doubleValue = 3.5
            if Defaults[.customAppSettings][selectedItem].hideAfter != 240 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 240
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 4 && value <= 6 {
            hideAfterLabel.stringValue = "5 minutes"
            sender.doubleValue = 5
            if Defaults[.customAppSettings][selectedItem].hideAfter != 300 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 300
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 6 && value <= 8 {
            hideAfterLabel.stringValue = "10 minutes"
            sender.doubleValue = 7
            if Defaults[.customAppSettings][selectedItem].hideAfter != 600 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 600
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 8 && value <= 12 {
            hideAfterLabel.stringValue = "15 minutes"
            sender.doubleValue = 10
            if Defaults[.customAppSettings][selectedItem].hideAfter != 900 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 900
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 12 && value <= 15 {
            hideAfterLabel.stringValue = "20 minutes"
            sender.doubleValue = 13.5
            if Defaults[.customAppSettings][selectedItem].hideAfter != 1200 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 1200
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 15 && value <= 17.5 {
            hideAfterLabel.stringValue = "25 minutes"
            sender.doubleValue = 16.25
            if Defaults[.customAppSettings][selectedItem].hideAfter != 1500 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 1500
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 17.5 && value <= 22.5 {
            hideAfterLabel.stringValue = "30 minutes"
            sender.doubleValue = 20
            if Defaults[.customAppSettings][selectedItem].hideAfter != 1800 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 1800
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 22.5 && value <= 25 {
            hideAfterLabel.stringValue = "35 minutes"
            sender.doubleValue = 23.75
            if Defaults[.customAppSettings][selectedItem].hideAfter != 35 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 35 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 25 && value <= 27.5 {
            hideAfterLabel.stringValue = "40 minutes"
            sender.doubleValue = 26.25
            if Defaults[.customAppSettings][selectedItem].hideAfter != 40 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 40 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 27.5 && value <= 32.5 {
            hideAfterLabel.stringValue = "45 minutes"
            sender.doubleValue = 30
            if Defaults[.customAppSettings][selectedItem].hideAfter != 45 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 45 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 32.5 && value <= 35 {
            hideAfterLabel.stringValue = "50 minutes"
            sender.doubleValue = 33.75
            if Defaults[.customAppSettings][selectedItem].hideAfter != 50 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 50 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 35 && value <= 37.5 {
            hideAfterLabel.stringValue = "55 minutes"
            sender.doubleValue = 36.25
            if Defaults[.customAppSettings][selectedItem].hideAfter != 55 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 55 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 37.5 && value <= 45 {
            hideAfterLabel.stringValue = "1 hour"
            sender.doubleValue = 40
            if Defaults[.customAppSettings][selectedItem].hideAfter != 60 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 60 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 45 && value <= 55 {
            hideAfterLabel.stringValue = "2 hours"
            sender.doubleValue = 50
            if Defaults[.customAppSettings][selectedItem].hideAfter != 2 * 60 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 2 * 60 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 55 && value <= 65 {
            hideAfterLabel.stringValue = "3 hours"
            sender.doubleValue = 60
            if Defaults[.customAppSettings][selectedItem].hideAfter != 3 * 60 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 3 * 60 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 65 && value <= 75 {
            hideAfterLabel.stringValue = "4 hours"
            sender.doubleValue = 70
            if Defaults[.customAppSettings][selectedItem].hideAfter != 4 * 60 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 4 * 60 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 75 && value <= 85 {
            hideAfterLabel.stringValue = "5 hours"
            sender.doubleValue = 80
            if Defaults[.customAppSettings][selectedItem].hideAfter != 5 * 60 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 5 * 60 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 85 && value <= 95 {
            hideAfterLabel.stringValue = "6 hours"
            sender.doubleValue = 90
            if Defaults[.customAppSettings][selectedItem].hideAfter != 6 * 60 * 60 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 6 * 60 * 60
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        } else if value > 95 && value <= 100 {
            hideAfterLabel.stringValue = "Never"
            sender.doubleValue = 100
            if Defaults[.customAppSettings][selectedItem].hideAfter != 0 {
                Defaults[.customAppSettings][selectedItem].hideAfter = 0
                NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
                if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
                    let setting = Defaults[.customAppSettings][selectedItem]
                    item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
                }
            }
        }
    }
    
    @IBAction func actionPopupDidChange(_ sender: Any) {
        guard let selectedItem = collectionView.selectionIndexes.first else { return }
        
        if actionPopupButton.indexOfSelectedItem == 0 {
            Defaults[.customAppSettings][selectedItem].action = .hide
        } else {
            Defaults[.customAppSettings][selectedItem].action = .quit
        }
        
        if let item = collectionView.item(at: selectedItem) as? AppCollectionViewItem {
            let setting = Defaults[.customAppSettings][selectedItem]
            item.label2.stringValue = setting.action == .hide ? "Hide, \(timeLabelFor(hideAfter: setting.hideAfter))" : "Quit, \(timeLabelFor(hideAfter: setting.hideAfter))"
        }
        
        NotificationCenter.default.post(name: .userDidUpdateAppSetting, object: self, userInfo: ["appName": Defaults[.customAppSettings][selectedItem].appName])
    }
    
}
