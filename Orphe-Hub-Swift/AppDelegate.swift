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
        
        OSCManager.sharedInstance.clientHost = AppSettings.oscHost
        OSCManager.sharedInstance.clientPort = AppSettings.oscSenderPort
        OSCManager.sharedInstance.serverPort = AppSettings.oscReceiverPort
        OSCManager.sharedInstance.startReceive()
        
        setOSCMappingValues(name: .Quaternion, mapValue: OSCManager.sharedInstance.quatMapValue)
        setOSCMappingValues(name: .Angle, mapValue: OSCManager.sharedInstance.eulerMapValue)
        setOSCMappingValues(name: .Accelerometer, mapValue: OSCManager.sharedInstance.accMapValue)
        setOSCMappingValues(name: .Gyroscope, mapValue: OSCManager.sharedInstance.gyroMapValue)
        setOSCMappingValues(name: .Magnetometer, mapValue: OSCManager.sharedInstance.magMapValue)
        setOSCMappingValues(name: .Shock, mapValue: OSCManager.sharedInstance.shockMapValue)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func setOSCMappingValues(name:mapSttingViewName, mapValue:MapValue){
        if let min = OSCMappingValues.getMin(name: name.rawValue){
            mapValue.min = min
        }
        if let max = OSCMappingValues.getMax(name: name.rawValue){
            mapValue.max = max
        }
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

