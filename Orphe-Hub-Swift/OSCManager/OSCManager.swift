//
//  OSCManager.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/04/01.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Orphe
import OSCKit

@objc public protocol OSCManagerDelegate : NSObjectProtocol {
    @objc optional func oscDidReceiveMessage(message:String)
}

class OSCManager:NSObject, OSCServerDelegate{
    
    static let sharedInstance = OSCManager()
    weak var delegate:OSCManagerDelegate?
    
    var server:OSCServer!
    var client:OSCClient!
    var clientPath = "udp://localhost:1234"
    var clientHost = "localhost" {
        didSet{
            clientPath = "udp://" + clientHost + ":" + String(clientPort)
        }
    }
    
    var clientPort = 1234 {
        didSet{
            clientPath = "udp://" + clientHost + ":" + String(clientPort)
        }
    }
    
    var serverPort = 4321
    
    private override init() {
        super.init()
        server = OSCServer()
        server.delegate = self
        
        client = OSCClient()
        
        NotificationCenter.default.addObserver(self, selector:  #selector(OSCManager.OrpheDidUpdateSensorData(notification:)), name: .OrpheDidUpdateSensorData, object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector(OSCManager.OrpheDidCatchGestureEvent(notification:)), name: .OrpheDidCatchGestureEvent, object: nil)
        
    }
    
    func stopReceive(){
        server.stop()
    }
    
    func startReceive()->Bool{
        
        do {
            try execute {
                self.server.listen(self.serverPort)
            }
        } catch let e {
            return false
        }
        return true
        
    }
    
    func execute(_ tryBlock: () -> ()) throws {
        try ObjC_Exception.catch(try: tryBlock)
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
        switch gesture.getGestureKind() {
        case .KICK:
            arguments.append("KICK")
            arguments.append("")
        case .STEP_TOE:
            arguments.append("STEP")
            arguments.append("TOE")
        case .STEP_FLAT:
            arguments.append("STEP")
            arguments.append("FLAT")
        case .STEP_HEEL:
            arguments.append("STEP")
            arguments.append("HEEL")
        default:
            break
        }
        
        arguments.append(gesture.getPower())
        let message = OSCMessage(address: address, arguments: arguments)
        client.send(message, to: clientPath)
    }
    
    func handle(_ message: OSCMessage!) {
        let oscAddress = message.address.components(separatedBy: "/")
        
        var isNoCommand = false
        var mString = ""
        
        //TODO: 左右ではなくID指定Orpheを選ぶようにする
        var orphes = [ORPData]()
        if oscAddress[1] == "LEFT"{
            orphes = ORPManager.sharedInstance.getOrpheArray(side: .left)
        }
        else if oscAddress[1] == "RIGHT"{
            orphes = ORPManager.sharedInstance.getOrpheArray(side: .right)
        }
        else if oscAddress[1] == "BOTH"{
            orphes = ORPManager.sharedInstance.connectedORPDataArray
        }
        else{
            mString = "You have to add '/BOTH' or '/LEFT' or '/RIGHT' to beginning of address. "
            delegate?.oscDidReceiveMessage?(message: mString)
            return
        }
        
        switch oscAddress[2] {
        case "triggerLight":
            for orphe in orphes{
                orphe.triggerLight(lightNum: message.arguments[3] as! UInt8)
            }
            
        case "triggerLightWithHSVColor":
            let lightNum = message.arguments[0] as! UInt8
            let hue = message.arguments[1] as! UInt16
            let sat = message.arguments[2] as! UInt8
            let bri = message.arguments[3] as! UInt8
            
            for orphe in orphes{
                orphe.triggerLightWithHSVColor(lightNum: lightNum, hue: hue, saturation: sat, brightness: bri)
            }
            
        case "triggerLightWithRGBColor":
            let lightNum = message.arguments[0] as! UInt8
            let red = message.arguments[1] as! UInt8
            let green = message.arguments[2] as! UInt8
            let blue = message.arguments[3] as! UInt8
            
            for orphe in orphes{
                orphe.triggerLightWithRGBColor(lightNum: lightNum, red: red, green: green, blue: blue)
            }
            
        case "setLightOn":
            for orphe in orphes{
                orphe.switchLight(lightNum: message.arguments[0] as! UInt8, flag: true)
            }
            
        case "setLightOff":
            for orphe in orphes{
                orphe.switchLight(lightNum: message.arguments[0] as! UInt8, flag: false)
            }
            
        case "setHSVColor":
            let lightNum = message.arguments[0] as! UInt8
            let hue = message.arguments[1] as! UInt16
            let sat = message.arguments[2] as! UInt8
            let bri = message.arguments[3] as! UInt8
            for orphe in orphes{
                orphe.setColorHSV(lightNum: lightNum, hue: hue, saturation: sat, brightness: bri)
            }
            
        case "setRGBColor":
            let lightNum = message.arguments[0] as! UInt8
            let red = message.arguments[1] as! UInt8
            let green = message.arguments[2] as! UInt8
            let blue = message.arguments[3] as! UInt8
            for orphe in orphes{
                orphe.setColorRGB(lightNum: lightNum, red: red, green: green, blue: blue)
            }
            
        default:
            isNoCommand = true
            PRINT("Wrong command")
            break
        }
        
        var args = ""
        if isNoCommand{
            mString = "Wrong command."
        }
        else{
            for arg in message.arguments{
                args +=  " " + String(describing: arg)
            }
            mString = message.address + args
        }
        delegate?.oscDidReceiveMessage?(message: mString)
    }
    
    //MARK: - Notifications
    
    func OrpheDidCatchGestureEvent(notification:Notification){
        guard let userInfo = notification.userInfo else {return}
        let gestureEvent = userInfo[OrpheGestureUserInfoKey] as! ORPGestureEventArgs
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        sendGesture(orphe: orphe, gesture: gestureEvent)
    }
    
    func OrpheDidUpdateSensorData(notification:Notification){
        guard let userInfo = notification.userInfo else {return}
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        let sendingType = userInfo[OrpheUpdatedSendingTypeInfoKey] as! SendingType
        if sendingType == .standard{
            sendSensorValues(orphe: orphe)
            return
        }
        let sensorKind = userInfo[OrpheUpdatedSenorKindInfoKey] as! SensorKind
        
        switch sendingType {
        case .t_2b_100h:
            for i in 0..<2{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            break
            
        case .t_2b_150h:
            for i in 0..<3{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            break
            
        case .t_1b_300h:
            for i in 0..<6{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            break
            
        case .t_2b_400h_1a:
            for i in 0..<8{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            break
            
        case .t_1b_400h_2a:
            for i in 0..<8{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            break
            
        default:
            break
        }
        
        
    }
    
    func sendCustomSensor(orphe:ORPData, sensorKind:SensorKind, index:Int){
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
        
        if sensorKind == .acc{
            args += orphe.accArray[index] as [Any]
            args += orphe.getGyro() as [Any]
        }
        else if sensorKind == .gyro{
            args += orphe.getAcc() as [Any]
            args += orphe.gyroArray[index] as [Any]
        }
        
        
        args.append(orphe.getMag() as Any)
        args.append(orphe.getShock() as Any)
        let message = OSCMessage(address: address, arguments: args)
        client.send(message, to: clientPath)
    }
}
