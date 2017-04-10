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
    
    var currentValue = Double(0.0)
    var minValue = Double(-38.0)
    var maxValue = Double(0.0)
    
    var valueArray = [Double]()
    var smooth = 0 //平均する配列の数
    
    var activeCalibration = false //今のところ足の水平だけ
    var isInvert = true //値の最大最小を逆転
    
    
    
    init() {
        
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
            currentValue = valueSum / Double(valueArray.count)
            
        }
        else{
            currentValue = value
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
        let mappedValue = map(value: currentValue, inputMin: minValue, inputMax: maxValue, outputMin: 0, outputMax: 16383.0, clamp: true)
        let pitchbendValue = UInt16(mappedValue) //0~16383.0
        print("pitchbend:",pitchbendValue)
        return pitchbendValue
    }
    
    func getCCValue() -> UInt8 {
        let mappedValue = map(value: currentValue, inputMin: minValue, inputMax: maxValue, outputMin: 0, outputMax: 127, clamp: true)
        let pitchbendValue = UInt8(mappedValue) //0~127
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
    
}
