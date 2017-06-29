//
//  SensorFreqencyCalculator.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/05/31.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Foundation

class SensorFreqencyCalculator: NSObject {
    
    var freq = 0 as Float
    var preValue = 0 as Float
    var preValue2 = 0 as Float
    var timestamp = Date()
    var counter = 0
    var preCounter = 0
    var difNumCounter = 0
    var countNum = 200
    var changeFrames = [Int]()
    var activeOutLog = false
    var isFreqValueUpdated = false
    
    func initValues(){
        freq = 0
        preValue = 0
        preValue2 = 0
        timestamp = Date()
        counter = 0
        preCounter = 0
        difNumCounter = 0
        changeFrames.removeAll()
    }
    
    func update(){
        counter += 1
        if counter == countNum {
            let elapsedTime = NSDate().timeIntervalSince(timestamp)
            timestamp = Date()
            freq = Float(counter)/Float(elapsedTime)
            counter = 0
            difNumCounter = 0
        }
    }
    
    func updateValue(value:Float){
        counter += 1
        if preValue != value {
            difNumCounter += 1
            preValue = value
        }
        
        if counter == countNum {
            let elapsedTime = NSDate().timeIntervalSince(timestamp)
            timestamp = Date()
            freq = Float(counter)/Float(elapsedTime)
            counter = 0
            difNumCounter = 0
            changeFrames.removeAll()
        }
    }
    
    func updateValue2(value:Float){
        isFreqValueUpdated = false
        counter += 1
        if preValue != value {
            changeFrames.append(counter-preCounter)
            preValue2 = preValue
            preValue = value
            preCounter = counter
        }
        
        if counter == countNum {
            let elapsedTime = NSDate().timeIntervalSince(timestamp)
            timestamp = Date()
            let mostFreqNum = mostFrequentNum(array: changeFrames)
            
            freq = Float(counter)/Float(elapsedTime)/Float(mostFreqNum)
            counter = 0
            preCounter = 0
            difNumCounter = 0
            changeFrames.removeAll()
            isFreqValueUpdated = true
        }
    }
    
    func mostFrequentNum(array:[Int])->Int{
        
        var dic = [Int:Int]()
        for value in array {
            if dic[value] != nil {
                dic[value] = dic[value]!+1
            }
            else{
                dic[value] = 1
            }
        }
        
        
        var maxNum = 0
        var mostFreqNum = 0
        if activeOutLog {
            print("======start======")
            for d in dic {
                if d.value > maxNum {
                    maxNum = d.value
                    mostFreqNum = d.key
                }
                print("key = ", d.key, ", count = ", d.value, "\n")
            }
            print("most freq num:", mostFreqNum)
            print("=======end=====")
        }
        else{
            for d in dic {
                if d.value > maxNum {
                    maxNum = d.value
                    mostFreqNum = d.key
                }
            }
        }
        
        return mostFreqNum
    }

}
