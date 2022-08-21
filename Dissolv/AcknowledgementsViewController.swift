//
//  AcknowledgementsViewController.swift
//  Dissolv
//
//  Created by Tomislav Filipcic on 21.08.2022..
//

import Cocoa

class AcknowledgementsViewController: NSViewController {
    @IBOutlet var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Acknowledgements"

        if let rtfFile = Bundle.main.url(forResource: "Acknowledgements", withExtension: "rtf"), let data = try? Data(contentsOf: rtfFile), let string = NSAttributedString(rtf: data, documentAttributes: nil) {
            textView.textStorage?.beginEditing()
            textView.textStorage?.setAttributedString(string)
            textView.textStorage?.endEditing()
        }

    }
    
}
