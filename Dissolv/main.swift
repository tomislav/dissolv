//
//  main.swift
//  Dissolv
//
//  Created by Tomislav Filipcic on 19.07.2022..
//

import Cocoa

// 1
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
