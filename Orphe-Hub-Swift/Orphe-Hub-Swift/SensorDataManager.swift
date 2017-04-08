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
    
    var valueRange = 38.0
    
    var counter = 0
    var sum = Double(0.0)
    var minValue = Double(0.0)
    var maxValue = Double(0.0)
    
    init() {
        minValue = -valueRange
    }
    
    func getPitchbendValue(value:Double) -> UInt16 {
        var pitch = value - maxValue
        if pitch < minValue {
            pitch = minValue
        }
        else if value > maxValue{
            pitch = maxValue
        }
        let pitchbendValue = UInt16(Int16(pitch * (16383.0 / minValue))) //-8192~8191
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
