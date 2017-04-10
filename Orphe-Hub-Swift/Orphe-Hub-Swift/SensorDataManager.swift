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

class SensorDataTuner{
    
    var valueRange = Double(0.0)
    
    var counter = 0
    var sum = Double(0.0)
    var minValue = Double(-38.0)
    var maxValue = Double(0.0)
    
    var valueArray = [Double]()
    var smooth = 0 //平均する配列の数
    
    var activeCalibration = false
    
    
    init() {
        valueRange = maxValue - minValue
    }
    
    func updateValue(_ value:Double){
        
        if smooth > 0 {
            valueArray.append(value)
            if valueArray.count > smooth{
                valueArray.remove(at: 0)
            }
        }
        
        
        if activeCalibration{
            calibrateFloorAngle(euler: value)
        }
    }
    
    func getPitchbendValue(value:Double) -> UInt16 {
        
        var pitch = value - maxValue
        if pitch < minValue {
            pitch = minValue
        }
        else if value > maxValue{
            pitch = maxValue
        }
        var mappedValue = pitch / minValue
        if mappedValue < 0{
            mappedValue = 0
        }
        let pitchbendValue = UInt16(Int16(mappedValue * 16383.0)) //0~16383.0
//        print("pitchbend:",pitchbendValue)
        return pitchbendValue
    }
    
    func getCCValue(value:Double) -> UInt8 {
        var pitch = value - maxValue
        if pitch < minValue {
            pitch = minValue
        }
        else if value > maxValue{
            pitch = maxValue
        }
        var val = pitch * (127 / minValue)
        if val < 0 {
            val = -val
        }
        let pitchbendValue = UInt8(val) //0~127
        //        print("pitchbend:",pitchbendValue)
        return pitchbendValue
    }
    
    func calibrateFloorAngle(euler:Double) {
        if euler > -5.0 && euler < 5.0 {
            sum += euler
            counter += 1
            
            if counter > 99 {
                print("Floor calibration!" + String(sum / Double(counter)))
                maxValue = sum / Double(counter)
                minValue = maxValue - valueRange
                counter = 0
                sum = Double(0.0)
            }
        }
    }
    
}
