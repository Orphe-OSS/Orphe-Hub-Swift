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
    
    static let sharedInstance = OSCManager()
    
    var server:OSCServer!
    var client:OSCClient!
    var clientPath = "udp://localhost:1234"
    var clientHost = "localhost" {
        didSet{
            clientPath = "udp://" + clientHost + ":" + clientPort
        }
    }
    
    var clientPort = "1234" {
        didSet{
            clientPath = "udp://" + clientPort + ":" + clientPort
        }
    }
    
    var serverPort = 4321{
        didSet{
            server.listen(serverPort)
        }
    }
    
    private override init() {
        super.init()
        server = OSCServer()
        server.delegate = self
        server.listen(serverPort)
        
        client = OSCClient()
        
        NotificationCenter.default.addObserver(self, selector:  #selector(OSCManager.OrpheDidUpdateSensorData(notification:)), name: .OrpheDidUpdateSensorData, object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector(OSCManager.OrpheDidCatchGestureEvent(notification:)), name: .OrpheDidCatchGestureEvent, object: nil)
        
    }
    
    func setHost(_ host:String){
        clientPath = clientPath + host + ":" + clientPort
    }
    
    
    
    func sendSensorValues(orphe:ORPData){
        var address = ""
        if orphe.side == .left{
            address = "/LEFT"
        }
        else{
            address = "/RIGHT"
        }
        address += "/sensorValues"
        var args = [Any]()
        args += orphe.getQuat() as [Any]
        args += orphe.getEuler() as [Any]
        args += orphe.getAcc() as [Any]
        args += orphe.getGyro() as [Any]
        args.append(orphe.getMag() as Any)
        args.append(orphe.getShock() as Any)
        let message = OSCMessage(address: address, arguments: args)
        client.send(message, to: clientPath)
    }
    
    func sendGesture(orphe:ORPData, gesture:ORPGestureEventArgs){
        var address = ""
        if orphe.side == .left{
            address = "/LEFT"
        }
        else{
            address = "/RIGHT"
        }
        address += "/gesture"
        var arguments = [Any]()
        arguments.append(gesture.getGestureKindString())
        arguments.append(gesture.getPower())
        let message = OSCMessage(address: address, arguments: arguments)
        client.send(message, to: clientPath)
    }
    
    func handle(_ message: OSCMessage!) {
        let oscAddress = message.address.components(separatedBy: "/")
        print(oscAddress)
        print(message.arguments)
        
        var side = ORPSide.left
        if oscAddress[1] == "RIGHT"{
            side = .right
        }
        
        let orphes = ORPManager.sharedInstance.getOrpheArray(side: side)
        var orphe:ORPData!
        if orphes.count > 0{
            orphe = orphes[0]
            
            switch oscAddress[2] {
            case "triggerLight":
                orphe.triggerLight(lightNum: message.arguments[3] as! UInt8)
                
            case "triggerLightWithHSVColor":
                break
            case "triggerLightWithRGBColor":
                break
            case "setLightOn":
                break
            case "setLightOff":
                break
            case "setHSVColor":
                break
            case "setRGBColor":
                break
            default:
                PRINT("No such command")
                break
            }
        }
    }
    
    //MARK: - Notifications
    func OrpheDidUpdateSensorData(notification:Notification){
        guard let userInfo = notification.userInfo else {return}
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        sendSensorValues(orphe: orphe)
    }
    
    func OrpheDidCatchGestureEvent(notification:Notification){
        guard let userInfo = notification.userInfo else {return}
        let gestureEvent = userInfo[OrpheGestureUserInfoKey] as! ORPGestureEventArgs
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        sendGesture(orphe: orphe, gesture: gestureEvent)
    }
    
}
