//
//  SensorValueCSVReader.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/21.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Foundation
import Orphe
import CSwiftV

class SensorValueCSVPlayer{
    
    var dummyOrphe:ORPData!
    var csv:CSwiftV?
    var currentRow = 0
    var isPlaying = false
    
    //"time,quatw,quatx,quaty,quatz,eulerx,eulery,eulerz,accx,accy,accz,gyrox,gyro y,gyroz,magx,magy,magz"
    enum csvKeys:String{
        case time
        case quatw
        case quatx
        case quaty
        case quatz
        case eulerx
        case eulery
        case eulerz
        case accx
        case accy
        case accz
        case gyrox
        case gyroy
        case gyroz
        case magx
        case magy
        case magz
        case shock
    }
    
    init(side:ORPSide) {
        dummyOrphe = ORPData()
        dummyOrphe.side = side
    }
    
    func loadCSVFile(url:URL){
        do{
            let csvString = try String(contentsOf: url, encoding: String.Encoding.utf8)
            csv = CSwiftV(with: csvString)
            PRINT(csv?.headers)
        } catch {
            ERROR("error")
        }
        
    }
    
    func play(){
        guard let _csv = self.csv else {return}
        isPlaying = true
        updateSensorValues()
    }
    
    func pause(){
        guard let _csv = self.csv else {return}
        isPlaying = false
    }
    
    func stop(){
        currentRow = 0
        isPlaying = false
        guard let _csv = self.csv else {return}
    }
    
    @objc func updateSensorValues(){
        if !isPlaying {return}
        guard let _csv = self.csv else {return}
        
        let quatw = Float(_csv.keyedRows![currentRow][csvKeys.quatw.rawValue]!)!
        let quatx = Float(_csv.keyedRows![currentRow][csvKeys.quatx.rawValue]!)!
        let quaty = Float(_csv.keyedRows![currentRow][csvKeys.quaty.rawValue]!)!
        let quatz = Float(_csv.keyedRows![currentRow][csvKeys.quatz.rawValue]!)!
        let quat = [quatw,quatx,quaty,quatz]
        
        let eulerx = Float(_csv.keyedRows![currentRow][csvKeys.eulerx.rawValue]!)!
        let eulery = Float(_csv.keyedRows![currentRow][csvKeys.eulery.rawValue]!)!
        let eulerz = Float(_csv.keyedRows![currentRow][csvKeys.eulerz.rawValue]!)!
        var euler = [eulerx,eulery,eulerz]
        euler = euler.map{$0/180}
        
        let gyrox = Float(_csv.keyedRows![currentRow][csvKeys.gyrox.rawValue]!)!
        let gyroy = Float(_csv.keyedRows![currentRow][csvKeys.gyroy.rawValue]!)!
        let gyroz = Float(_csv.keyedRows![currentRow][csvKeys.gyroz.rawValue]!)!
        var gyro = [gyrox,gyroy,gyroz]
        gyro = gyro.map{$0/Float(dummyOrphe.getGyroRange().rawValue)}
        
        let accx = Float(_csv.keyedRows![currentRow][csvKeys.accx.rawValue]!)!
        let accy = Float(_csv.keyedRows![currentRow][csvKeys.accy.rawValue]!)!
        let accz = Float(_csv.keyedRows![currentRow][csvKeys.accz.rawValue]!)!
        var acc = [accx,accy,accz]
        acc = acc.map{$0/Float(dummyOrphe.getAccRange().rawValue)}
        
//        let magx = Float(_csv.keyedRows![currentRow][csvKeys.magx.rawValue]!)!
//        let magy = Float(_csv.keyedRows![currentRow][csvKeys.magy.rawValue]!)!
        let magz = Float(_csv.keyedRows![currentRow][csvKeys.magz.rawValue]!)!
//        let mag = [magx,magy,magz]
        
        let shock = UInt8(0)//UInt8(_csv.keyedRows![currentRow][csvKeys.shock.rawValue]!)!
        
        self.dummyOrphe.sensorValue(quat: quat, euler: euler, acc: acc, gyro: gyro, mag: UInt16(magz), shock: shock)
        NotificationCenter.default.post(name: .OrpheDidUpdateSensorData, object: nil, userInfo: [OrpheDataUserInfoKey:self.dummyOrphe, OrpheUpdatedSendingTypeInfoKey:SendingType.standard])
        
        //row count
        self.currentRow += 1
        if currentRow == csv?.rows.count {
            isPlaying = false
            currentRow = 0
            return
        }
        
        //loop
        let time = Double(_csv.keyedRows![currentRow-1][csvKeys.time.rawValue]!)!
        let nextTime = Double(_csv.keyedRows![currentRow][csvKeys.time.rawValue]!)!
        let delayTime = nextTime - time
        let popTime = DispatchTime.now() + delayTime  - 0.0023 //0.0023引いているのはちょっと短くしないと５hzくらい遅くなる
        DispatchQueue.main.asyncAfter(deadline: popTime,  execute: {
            self.updateSensorValues()
        })
        
    }
    
}
