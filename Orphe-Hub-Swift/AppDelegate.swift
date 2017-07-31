//
//  AppDelegate.swift
//  OrpheExample_macOS
//
//  Created by no new folk studio Inc. on 2016/12/21.
//  Copyright © 2016 no new folk studio Inc. All rights reserved.
//

import Cocoa

enum mapSttingViewName:String {
    case Quaternion
    case Angle
    case Accelerometer
    case Gyroscope
    case Magnetometer
    case Shock
}

func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
    var i = 0
    return AnyIterator {
        let next = withUnsafeBytes(of: &i) { $0.load(as: T.self) }
        if next.hashValue != i { return nil }
        i += 1
        return next
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var activity: NSObjectProtocol?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("applicationDidFinishLaunching")
        // Insert code here to initialize your application
        
        activity = ProcessInfo().beginActivity(options: ProcessInfo.ActivityOptions.userInitiated, reason: "Good Reason")
        
        OSCManager.sharedInstance.startReceive()
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func helpMenuItemAction(_ sender: NSMenuItem) {
        if let url = URL(string: "https://sites.google.com/view/orphe-developers/hub-app/how-to-use"), NSWorkspace.shared().open(url) {
            print("default browser was successfully opened")
        }
    }
    
    @IBAction func oscCommandsItemAction(_ sender: NSMenuItem) {
        if let url = URL(string: "https://sites.google.com/view/orphe-developers/hub-app/api"), NSWorkspace.shared().open(url) {
            print("default browser was successfully opened")
        }
    }
    
}

