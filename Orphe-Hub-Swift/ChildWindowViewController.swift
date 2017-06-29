//
//  ChildWindowViewController.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/29.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa

//escキーでウィンドウを閉じるのをアクティブなウィンドウのみに適応するためのクラス
class ChildWindowViewController: NSViewController {
    
    fileprivate var eventMonitor: Any?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let window = view.window{
            window.delegate = self
        }
        else{
            
        }
    }
    
}

//MARK: - NSWindowDelegate
extension ChildWindowViewController: NSWindowDelegate {
    func windowDidBecomeMain(_ notification: Notification) {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            if event.keyCode == 53 {
                self.view.window?.close()
            }
            return event
        }
    }
    
    func windowDidResignMain(_ notification: Notification) {
        NSEvent.removeMonitor(eventMonitor!)
    }
    
}
