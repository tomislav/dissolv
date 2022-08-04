import Cocoa
import Preferences
import OSLog
import Defaults

final class AdvancedSettingsViewController: NSViewController, SettingsPane, AddApplicationDelegate, NSCollectionViewDelegate, NSCollectionViewDataSource {
	let preferencePaneIdentifier = Settings.PaneIdentifier.advanced
	let preferencePaneTitle = "Advanced"
	let toolbarItemIcon = NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: "Advanced settings")!

    @IBOutlet weak var collectionView: NSCollectionView!
    
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
	}
    
    @IBAction func segmentedControlPress(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            logger.debug("add")
            let controller = AddApplicationViewController()
            controller.delegate = self
            self.presentAsSheet(controller)
        } else if sender.selectedSegment == 1 {
            logger.debug("remove")
        }
    }
    
    func didSelectApplications(apps: [String], controller: AddApplicationViewController) {
        self.dismiss(controller)
        
        for app in apps {
            let settings = CustomAppSetting(appName: app, hideAfter: Defaults[.hideAfter], action: .hide)
            Defaults[.customAppSettings].append(settings)
            
        }
        
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return Defaults[.customAppSettings].count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "App"), for: indexPath) as! AppCollectionViewItem
        let setting = Defaults[.customAppSettings][indexPath.item]
        item.label1.stringValue = setting.appName
        item.label2.stringValue = setting.active ? "Active" : "Disabled"
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first
            else { return }
        guard let item = collectionView.item(at: indexPath)
            else { return }
        item.isSelected = true
    }
}
