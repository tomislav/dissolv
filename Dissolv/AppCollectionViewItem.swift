//
//  AppCollectionViewItem.swift
//  Dissolv
//
//  Created by Tomislav Filipcic on 02.08.2022..
//

import Cocoa

class AppCollectionViewItem: NSCollectionViewItem {
    @IBOutlet weak var label1: NSTextField!
    @IBOutlet weak var label2: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer?.cornerRadius = 9
    }
    
    override var isSelected: Bool {
      didSet {
          self.view.layer?.backgroundColor = isSelected ? NSColor.systemBlue.cgColor : NSColor.clear.cgColor
          self.label1.textColor = isSelected ? NSColor.white : NSColor.labelColor
          self.label2.textColor = isSelected ? NSColor.white : NSColor.labelColor
      }
    }
}
