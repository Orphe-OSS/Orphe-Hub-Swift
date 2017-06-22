//
//  SensorValueCSVReader.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/21.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Foundation
import Orphe

class SensorValueCSVPlayer{
    
    var dummyOrphe:ORPData!
    
    init() {
        
    }
    
    func loadCSVFile(filePath:String){
        do{
            let csvString = try String(contentsOfFile:filePath, encoding:String.Encoding.utf8)
            parseCSVString(csvString: csvString)
        } catch {
            ERROR("error")
        }
        
    }
    
    func parseCSVString(csvString:String){
        
        dummyOrphe.sensorValue(quat: <#T##[Float]#>, euler: <#T##[Float]#>, acc: <#T##[Float]#>, gyro: <#T##[Float]#>, mag: <#T##UInt16#>, shock: <#T##UInt8#>)
    }
    
}
