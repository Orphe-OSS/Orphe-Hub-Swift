//
//  SensorMappingManager.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/04/08.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Foundation
import Orphe

class SensorDataManager{
    
    static let sharedInstance = SensorDataManager()
    
}

public protocol EnumEnumerable {
    associatedtype Case = Self
}

public extension EnumEnumerable where Case: Hashable {
    fileprivate static var generator: AnyIterator<Case> {
        var n = 0
        return AnyIterator {
            defer { n += 1 }
            let next = withUnsafePointer(to: &n) { UnsafeRawPointer($0).load(as: Case.self) }
            return next.hashValue == n ? next : nil
        }
    }
    
    @warn_unused_result
    public static func enumerate() -> EnumeratedSequence<AnySequence<Case>> {
        return AnySequence(generator).enumerated()
    }
    
    public static var cases: [Case] {
        return Array(generator)
    }
    
    public static var count: Int {
        return cases.count
    }
}

enum SensorKind:String, EnumEnumerable{
    case eulerX = "eulerX"
    case eulerY = "eulerY"
    case eulerZ = "eulerZ"
    case gyroX = "gyroX"
    case gyroY = "gyroY"
    case gyroZ = "gyroZ"
    case accX = "accX"
    case accY = "accY"
    case accZ = "accZ"

}

enum MIDIStatus:String, EnumEnumerable{
    case pitchBend = "Pitch Bend"
    case controlChange = "Control Change"
}

class MIDISensorMapper:NSObject{
    
    let controlChangeMaxValue = 127.0
    var controlNumber = UInt8(0)
    let pitchBendMaxValue = 16383.0
    
    weak var orphe:ORPData!
    
    var currentInputValue = Double(0.0)
    var currentOutputValue = Double(0.0)
    var minValue = Double(-38.0)
    var maxValue = Double(0.0)
    var outputMinValue = Double(0.0)
    var outputMaxValue = Double(0.0)
    
    
    var valueArray = [Double]()
    var smooth = 0 //平均する配列の数
    
    var isAbsolute = false //絶対値にする
    
    var activeCalibration = false //今のところ足の水平だけ
    var isInvert = true //値の最大最小を逆転
    
    var midiStatus = MIDIStatus.pitchBend{
        didSet{
            switch midiStatus {
            case .controlChange:
                outputMinValue = 0
                outputMaxValue = controlChangeMaxValue
            case .pitchBend:
                outputMinValue = 0
                outputMaxValue = pitchBendMaxValue
            default:
                break
            }
            
        }
    }
    var sensorKind:SensorKind = .eulerX {
        didSet{
            if sensorKind == .eulerX{
                activeCalibration = true
            }
            else{
                activeCalibration = false
            }
            switch sensorKind {
            case .accX:
                maxValue = 1
                minValue = -1
            case .accY:
                maxValue = 1
                minValue = -1
            case .accZ:
                maxValue = 1
                minValue = -1
            case .eulerX:
                maxValue = 0
                minValue = -38.0
            case .eulerY:
                maxValue = 180
                minValue = -180
            case .eulerZ:
                maxValue = 180
                minValue = -180
            case .gyroX:
                maxValue = 1
                minValue = -1
            case .gyroY:
                maxValue = 1
                minValue = -1
            case .gyroZ:
                maxValue = 1
                minValue = -1
            default:
                break
            }
        }
    }
    
    init(orphe:ORPData) {
        super.init()
        self.orphe = orphe
        NotificationCenter.default.addObserver(self, selector: #selector(orpheDidUpdateSensorData(notification:)), name: .OrpheDidUpdateSensorData, object: nil)
        
        midiStatus = .controlChange
        outputMinValue = 0
        outputMaxValue = controlChangeMaxValue
    }
    
    func updateValue(_ value:Double){
        
        if smooth > 0 {
            valueArray.append(value)
            if valueArray.count > smooth{
                valueArray.remove(at: 0)
            }
            
            var valueSum = 0.0
            for val in valueArray {
                valueSum += val
            }
            currentInputValue = valueSum / Double(valueArray.count)
            
        }
        else{
            currentInputValue = value
        }
        
        
        if activeCalibration{
            calibrateFloorAngle(euler: value)
        }
    }
    
    func map(value:Double, inputMin:Double, inputMax:Double, outputMin:Double, outputMax:Double, clamp:Bool)->Double{
        if fabs(inputMin - inputMax) < DBL_EPSILON{
            return outputMin;
        }
        else {
            var _inputMin = inputMin
            var _inputMax = inputMax
            if isInvert{
                _inputMin = inputMax
                _inputMax = inputMin
            }
            
            var outVal = ((value - _inputMin) / (_inputMax - _inputMin) * (outputMax - outputMin) + outputMin)
            
            if( clamp ){
                if(outputMax < outputMin){
                    if outVal < outputMax {
                        outVal = outputMax
                    }
                    else if outVal > outputMin {
                        outVal = outputMin
                    }
                }else{
                    if outVal > outputMax {
                        outVal = outputMax
                    }
                    else if outVal < outputMin {
                        outVal = outputMin
                    }
                }
            }
            return outVal;
        }
    }
    
    
    func getPitchbendValue() -> UInt16 {
        currentOutputValue = map(value: currentInputValue, inputMin: minValue, inputMax: maxValue, outputMin: 0, outputMax: pitchBendMaxValue, clamp: true)
        let pitchbendValue = UInt16(currentOutputValue) //0~16383.0
        return pitchbendValue
    }
    
    func getCCValue() -> UInt8 {
        currentOutputValue = map(value: currentInputValue, inputMin: minValue, inputMax: maxValue, outputMin: 0, outputMax: controlChangeMaxValue, clamp: true)
        let pitchbendValue = UInt8(currentOutputValue) //0~127
        return pitchbendValue
    }
    
    var calibCounter = 0
    var calibSum = Double(0.0)
    func calibrateFloorAngle(euler:Double) {
        if euler > -5.0 && euler < 5.0 {
            calibSum += euler
            calibCounter += 1
            
            if calibCounter > 99 {
                print("Floor calibration!" + String(calibSum / Double(calibCounter)))
                let valueRange = maxValue - minValue
                maxValue = calibSum / Double(calibCounter)
                minValue = maxValue - valueRange
                calibCounter = 0
                calibSum = Double(0.0)
            }
        }
    }
    
    var sendMessageOrpheTimeStamp:Double = 0
    func orpheDidUpdateSensorData(notification:Notification){
        guard let userInfo = notification.userInfo else {return}
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        
        if orphe == self.orphe{
            
            updateValue(Double(getSelectedSensorValue()))
            
            currentOutputValue = map(value: currentInputValue, inputMin: minValue, inputMax: maxValue, outputMin: outputMinValue, outputMax: outputMaxValue, clamp: true)
            
            let elapsedTime = NSDate().timeIntervalSince1970 - sendMessageOrpheTimeStamp
            if elapsedTime > 30 {
                let hue = (currentOutputValue/outputMaxValue*0.5 + 0.5) * 359
                let bri = currentOutputValue/outputMaxValue * 255
                orphe.setColorHSV(lightNum: 5, hue: UInt16(hue), saturation: 255, brightness: UInt8(bri))
            }
            
            // select control
            switch midiStatus {
            case .pitchBend:
                MIDIManager.sharedInstance.pitchbendReceive(ch: 0, pitchbendValue: UInt16(currentOutputValue))
            case .controlChange:
                MIDIManager.sharedInstance.controlChangeReceive(ch: 0, ctNum: controlNumber, value: UInt8(currentOutputValue))
            }
            
        }
        
    }
    
    func getSelectedSensorValue()->Float{
        switch sensorKind {
        case .accX:
            return orphe.getAcc()[0]
        case .accY:
            return orphe.getAcc()[1]
        case .accZ:
            return orphe.getAcc()[2]
        case .eulerX:
            return orphe.getEuler()[0]
        case .eulerY:
            return orphe.getEuler()[1]
        case .eulerZ:
            return orphe.getEuler()[2]
        case .gyroX:
            return orphe.getGyro()[0]
        case .gyroY:
            return orphe.getGyro()[1]
        case .gyroZ:
            return orphe.getGyro()[2]
        default:
            break
        }
        return 0
    }
    
    let EULER_MAX = 180
    
    func getNormalizedSelectedSensorValue()->Float{
        switch sensorKind {
        case .accX:
            return orphe.getAcc()[0]
        case .accY:
            return orphe.getAcc()[1]
        case .accZ:
            return orphe.getAcc()[2]
        case .eulerX:
            return orphe.getEuler()[0] / Float(EULER_MAX)
        case .eulerY:
            return orphe.getEuler()[1] / Float(EULER_MAX)
        case .eulerZ:
            return orphe.getEuler()[2] / Float(EULER_MAX)
        case .gyroX:
            return orphe.getGyro()[0]
        case .gyroY:
            return orphe.getGyro()[1]
        case .gyroZ:
            return orphe.getGyro()[2]
        default:
            break
        }
        return 0
    }
    
    func getNormalizedCurrnetValue()->Double{
        switch midiStatus {
        case .pitchBend:
            return currentOutputValue/pitchBendMaxValue
        case .controlChange:
            return currentOutputValue/controlChangeMaxValue
        default:
            return 0
        }
    }
    
}
