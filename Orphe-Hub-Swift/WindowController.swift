//
//  WindowController.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/27.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    var childWindows = [NSWindow]()
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window!.delegate = self
    }
    
}

extension WindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared().terminate(self.window!)
        
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        for window in NSApplication.shared().windows{
            if !(window.contentViewController is ViewController){
                window.level = Int(CGWindowLevelKey.floatingWindow.rawValue)
            }
        }
    }
    
    func windowDidResignMain(_ notification: Notification) {
        for window in NSApplication.shared().windows{
            if !(window.contentViewController is ViewController){
                window.level = Int(CGWindowLevelKey.baseWindow.rawValue)
            }
        }
    }
    
}
