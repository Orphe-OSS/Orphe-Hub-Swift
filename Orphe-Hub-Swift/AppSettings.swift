//
//  AppSettings.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/28.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Foundation

class AppSettings {
    static let ud = UserDefaults.standard
    
    static func reset(){
        
    }
    
    // set default settings here
    struct DefaultSetting {
        static let oscHost: String = "localhost"
        static let oscSenderPort: Int = 1234
        static let oscReceiverPort: Int = 4321
    }
    
    class var oscHost: String {
        get {
            ud.register(defaults: ["oscHost": DefaultSetting.oscHost])
            return ud.object(forKey: "oscHost") as! String
        }
        set(newValue) {
            ud.set(newValue, forKey: "oscHost")
            ud.synchronize()
        }
    }
    
    class var oscSenderPort: Int {
        get {
            ud.register(defaults: ["oscSenderPort": DefaultSetting.oscSenderPort])
            return ud.object(forKey: "oscSenderPort") as! Int
        }
        set(newValue) {
            ud.set(newValue, forKey: "oscSenderPort")
            ud.synchronize()
        }
    }
    
    class var oscReceiverPort: Int {
        get {
            ud.register(defaults: ["oscReceiverPort": DefaultSetting.oscReceiverPort])
            return ud.object(forKey: "oscReceiverPort") as! Int
        }
        set(newValue) {
            ud.set(newValue, forKey: "oscReceiverPort")
            ud.synchronize()
        }
    }

}
