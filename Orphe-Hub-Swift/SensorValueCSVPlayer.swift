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

extension Notification.Name {
    public static let SensorValueCSVPlayerStartPlaying = Notification.Name("SensorValueCSVPlayerStartPlaying")
    public static let SensorValueCSVPlayerStopPlaying = Notification.Name("SensorValueCSVPlayerStopPlaying")
}

//user info keys
public let SensorValueCSVPlayerInfoKey = "SensorValueCSVPlayerInfoKey"

class SensorValueCSVPlayer{
    
    var dummyOrphe:ORPData!
    var csv:CSwiftV?
    var currentRow = 0
    var isPlaying = false {
        didSet{
            if isPlaying{
                NotificationCenter.default.post(name: .SensorValueCSVPlayerStartPlaying, object: nil, userInfo: [SensorValueCSVPlayerInfoKey:self])
            }
            else{
                NotificationCenter.default.post(name: .SensorValueCSVPlayerStopPlaying, object: nil, userInfo: [SensorValueCSVPlayerInfoKey:self])
            }
        }
    }
    var isLoop = true
    
    //“timestamp,quatW,quatX,quatY,quatZ,eulerX,eulerY,eulerZ,gyroX,gyroY,gyroZ,magX,magY,magZ,accX,accY,accZ,shock
    enum csvKeys:String{
        case timestamp
        case quatW
        case quatX
        case quatY
        case quatZ
        case eulerX
        case eulerY
        case eulerZ
        case gyroX
        case gyroY
        case gyroZ
        case magX
        case magY
        case magZ
        case accX
        case accY
        case accZ
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
    
    func play()->Bool{
        guard let _csv = self.csv else {return false}
        if !isPlaying{
            isPlaying = true
            updateSensorValues()
            return true
        }
        else{
            return false
        }
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
        
        let quatw = Float(_csv.keyedRows![currentRow][csvKeys.quatW
            .rawValue]!)!
        let quatx = Float(_csv.keyedRows![currentRow][csvKeys.quatX.rawValue]!)!
        let quaty = Float(_csv.keyedRows![currentRow][csvKeys.quatY.rawValue]!)!
        let quatz = Float(_csv.keyedRows![currentRow][csvKeys.quatZ.rawValue]!)!
        let quat = [quatw,quatx,quaty,quatz]
        
        let eulerx = Float(_csv.keyedRows![currentRow][csvKeys.eulerX.rawValue]!)!
        let eulery = Float(_csv.keyedRows![currentRow][csvKeys.eulerY.rawValue]!)!
        let eulerz = Float(_csv.keyedRows![currentRow][csvKeys.eulerZ.rawValue]!)!
        var euler = [eulerx,eulery,eulerz]
        euler = euler.map{$0/180}
        
        let gyrox = Float(_csv.keyedRows![currentRow][csvKeys.gyroX.rawValue]!)!
        let gyroy = Float(_csv.keyedRows![currentRow][csvKeys.gyroY.rawValue]!)!
        let gyroz = Float(_csv.keyedRows![currentRow][csvKeys.gyroZ.rawValue]!)!
        var gyro = [gyrox,gyroy,gyroz]
        gyro = gyro.map{$0/Float(dummyOrphe.getGyroRange().rawValue)}
        
        let accx = Float(_csv.keyedRows![currentRow][csvKeys.accX.rawValue]!)!
        let accy = Float(_csv.keyedRows![currentRow][csvKeys.accY.rawValue]!)!
        let accz = Float(_csv.keyedRows![currentRow][csvKeys.accZ.rawValue]!)!
        var acc = [accx,accy,accz]
        acc = acc.map{$0/Float(dummyOrphe.getAccRange().rawValue)}
        
//        let magx = Float(_csv.keyedRows![currentRow][csvKeys.magx.rawValue]!)!
//        let magy = Float(_csv.keyedRows![currentRow][csvKeys.magy.rawValue]!)!
        let magz = Float(_csv.keyedRows![currentRow][csvKeys.magZ.rawValue]!)!
//        let mag = [magx,magy,magz]
        
        let shock = UInt8(_csv.keyedRows![currentRow][csvKeys.shock.rawValue]!)!
        
        DispatchQueue.main.async {
            // Main Threadで実行する
            self.dummyOrphe.sensorValue(quat: quat, euler: euler, acc: acc, gyro: gyro, mag: UInt16(magz), shock: shock)
            NotificationCenter.default.post(name: .OrpheDidUpdateSensorData, object: nil, userInfo: [OrpheDataUserInfoKey:self.dummyOrphe, OrpheUpdatedSendingTypeInfoKey:SendingType.standard])
        }
        
        //row count
        self.currentRow += 1
        if currentRow == csv?.rows.count {
            currentRow = 0
            if isLoop {
                //最初から再生
                let popTime = DispatchTime.now() + 0.020
                DispatchQueue.global().asyncAfter(deadline: popTime,  execute: {
                    self.updateSensorValues()
                })
            }
            else{
                //終了
                isPlaying = false
            }
            return
        }
        
        //loop
        let time = Double(_csv.keyedRows![currentRow-1][csvKeys.timestamp.rawValue]!)!
        let nextTime = Double(_csv.keyedRows![currentRow][csvKeys.timestamp.rawValue]!)!
        let delayTime = nextTime - time
        let popTime = DispatchTime.now() + delayTime  - 0.0023 //0.0023引いているのはちょっと短くしないと５hzくらい遅くなる
        DispatchQueue.global().asyncAfter(deadline: popTime,  execute: {
            self.updateSensorValues()
        })
        
    }
    
}
