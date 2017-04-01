//
//  OSCManager.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/04/01.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Orphe
import OSCKit

class OSCManager:NSObject, OSCServerDelegate{
    
    var server:OSCServer!
    
    static let sharedInstance = OSCManager()
    
    private override init() {
        super.init()
        server = OSCServer()
        server.delegate = self
        server.listen(8000)
    }
    
    
    
    func handle(_ message: OSCMessage!) {
        print(message.attributeKeys)
        print(message.arguments)
        let address = message.address
        
        switch message.address {
        case "":
            break
        default:
            PRINT("No such command")
            break
        }
    }
    
}
