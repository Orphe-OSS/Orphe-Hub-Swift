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

class MapValue{
    var min:Float = -1.0
    var max:Float = 1.0
    public func map(_ val: Float, inputMin: Float, inputMax: Float) -> Float {
        let param = (val - inputMin)/(inputMax -  inputMin)
        return lerp(min, max, at: param)
    }
    public func lerp(_ a: Float, _ b: Float, at: Float) -> Float {
        return a + (b - a) * at
    }
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
    var isReceiving = false
    var oscReceivedMessages = [String]()
    
    var quatMapValue:MapValue = MapValue()
    var eulerMapValue:MapValue = MapValue()
    var accMapValue:MapValue = MapValue()
    var gyroMapValue:MapValue = MapValue()
    var magMapValue:MapValue = MapValue()
    var shockMapValue:MapValue = MapValue()
    
    var accRange:Float = 2.0{
        didSet{
            accMapValue.max = accRange
            accMapValue.min = -accRange
        }
    }
    var gyroRange:Float = 2000.0{
        didSet{
            gyroMapValue.max = gyroRange
            gyroMapValue.min = -gyroRange
        }
    }
    
    private override init() {
        super.init()
        server = OSCServer()
        server.delegate = self
        
        client = OSCClient()
        
        accMapValue.max = accRange
        accMapValue.min = -accRange
        gyroMapValue.max = gyroRange
        gyroMapValue.min = -gyroRange
        eulerMapValue.max = 180
        eulerMapValue.min = -180
        shockMapValue.max = 255
        shockMapValue.min = 0
        magMapValue.max = 359
        magMapValue.min = 0
        
        NotificationCenter.default.addObserver(self, selector:  #selector(OSCManager.OrpheDidUpdateSensorData(notification:)), name: .OrpheDidUpdateSensorData, object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector(OSCManager.OrpheDidCatchGestureEvent(notification:)), name: .OrpheDidCatchGestureEvent, object: nil)
        
    }
    
    func stopReceive(){
        server.stop()
        isReceiving = false
    }
    
    func startReceive()->Bool{
        
        do {
            try execute {
                self.server.listen(self.serverPort)
            }
        } catch let e {
            return false
        }
        isReceiving = true
        return true
        
    }
    
    func execute(_ tryBlock: () -> ()) throws {
        try ObjC_Exception.catch(try: tryBlock)
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
    
    func addReceivedOSCMessage(message:String){
        oscReceivedMessages.append(message)
        if oscReceivedMessages.count > 30{
            oscReceivedMessages.remove(at: 0)
        }
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
            addReceivedOSCMessage(message: mString)
            delegate?.oscDidReceiveMessage?(message: mString)
            return
        }
        
        switch oscAddress[2] {
        case "triggerLight":
            for orphe in orphes{
                orphe.triggerLight(lightNum: message.arguments[0] as! UInt8)
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
            
        case "changeScene":
            let sceneNum = message.arguments[0] as! Int
            if let scene = ORPScene(rawValue: sceneNum){
                for orphe in orphes{
                    orphe.setScene(scene)
                }
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
        addReceivedOSCMessage(message: mString)
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
        let sendingType = userInfo[OrpheUpdatedTransmissionOptionInfoKey] as! TransmissionOption
        
        let sensorKind = userInfo[OrpheUpdatedSenorKindInfoKey] as? SensorKind
        
        switch sendingType {
        case .standard:
            sendCustomSensor(orphe: orphe, sensorKind: nil, index: 0)
            
        case ._100hz_2byte:
            for i in 0..<2{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            
        case ._150hz_2byte:
            for i in 0..<3{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            
        case ._300hz_1byte:
            for i in 0..<6{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            
        case ._400hz_2byte_1axis:
            for i in 0..<8{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            
        case ._400hz_1byte_2axes:
            for i in 0..<8{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            
        case ._200hz_2byte_2axes:
            for i in 0..<4{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            
        case ._200hz_4byte_1axis:
            for i in 0..<4{
                sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: i)
            }
            
        case ._50hz_4byte:
            sendCustomSensor(orphe: orphe, sensorKind: sensorKind, index: 0)
        }
        
        
    }
    
    func sendCustomSensor(orphe:ORPData, sensorKind:SensorKind?, index:Int){
        var address = ""
        if orphe.side == .left{
            address = "/LEFT"
        }
        else{
            address = "/RIGHT"
        }
        address += "/sensorValues"
        var args = [Any]()
        
        //quat
        do{
            var inputArray = [Float]()
            if orphe.quatArray.count > index{
                inputArray = orphe.quatArray[index]
            }
            else{
                inputArray = orphe.getQuat()
            }
            var outputArray = [Float]()
            for input in inputArray{
                let output = quatMapValue.map(input, inputMin: -1, inputMax: 1)
                outputArray.append(output)
            }
            args += outputArray as [Any]
        }
        
        //euler
        do{
            var inputArray = [Float]()
            if orphe.eulerArray.count > index{
                inputArray = orphe.eulerArray[index]
            }
            else{
                inputArray = orphe.getEuler()
            }
            var outputArray = [Float]()
            for input in inputArray{
                let output = eulerMapValue.map(input, inputMin: -180, inputMax: 180)
                outputArray.append(output)
            }
            args += outputArray as [Any]
        }
        
        //acc
        do{
            var inputArray = [Float]()
            if orphe.accArray.count > index{
                inputArray = orphe.accArray[index]
            }
            else{
                inputArray = orphe.getAcc()
            }
            var outputArray = [Float]()
            for input in inputArray{
                let output = accMapValue.map(input, inputMin: -Float(orphe.getCurrentAccRange().rawValue), inputMax: Float(orphe.getCurrentAccRange().rawValue))
                outputArray.append(output)
            }
            args += outputArray as [Any]
        }
        
        //gyro
        do{
            var inputArray = [Float]()
            if orphe.gyroArray.count > index{
                inputArray = orphe.gyroArray[index]
            }
            else{
                inputArray = orphe.getGyro()
            }
            var outputArray = [Float]()
            for input in inputArray{
                let output = gyroMapValue.map(input, inputMin: -Float(orphe.getCurrentGyroRange().rawValue), inputMax: Float(orphe.getCurrentGyroRange().rawValue))
                outputArray.append(output)
            }
            args += outputArray as [Any]
        }
        
        //mag
        let outputMag = magMapValue.map(orphe.getMag(), inputMin: 0, inputMax: 359)
        args.append(outputMag as Any)
        
        //shock
        let outputShock = shockMapValue.map(Float(orphe.getShock()), inputMin: 0, inputMax: 255)
        args.append(outputShock as Any)
        
        //gravity
        do{
            var inputArray = [Float]()
            if orphe.accOfGravityArray.count > index{
                inputArray = orphe.accOfGravityArray[index]
            }
            else{
                inputArray = orphe.getAccOfGravity()
            }
            args += inputArray as [Any]
        }
        
        
        let message = OSCMessage(address: address, arguments: args)
        client.send(message, to: clientPath)
    }
}
