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
        guard let csv = self.csv else {return}
        
        //文字列からスペースを削除
        var keyRows = csv.keyedRows![currentRow]
        for val in keyRows{
            keyRows[val.key] = keyRows[val.key]?.replacingOccurrences(of: " ", with: "")
        }
        
        let quatw = Float(keyRows[csvKeys.quatW.rawValue] ?? "0")!
        let quatx = Float(keyRows[csvKeys.quatX.rawValue] ?? "0")!
        let quaty = Float(keyRows[csvKeys.quatY.rawValue] ?? "0")!
        let quatz = Float(keyRows[csvKeys.quatZ.rawValue] ?? "0")!
        let quat = [quatw,quatx,quaty,quatz]
        
        let eulerx = Float(keyRows[csvKeys.eulerX.rawValue] ?? "0")!
        let eulery = Float(keyRows[csvKeys.eulerY.rawValue] ?? "0")!
        let eulerz = Float(keyRows[csvKeys.eulerZ.rawValue] ?? "0")!
        let euler = [eulerx,eulery,eulerz]
        
        let gyrox = Float(keyRows[csvKeys.gyroX.rawValue] ?? "0")!
        let gyroy = Float(keyRows[csvKeys.gyroY.rawValue] ?? "0")!
        let gyroz = Float(keyRows[csvKeys.gyroZ.rawValue] ?? "0")!
        let gyro = [gyrox,gyroy,gyroz]
        
        let accx = Float((keyRows[csvKeys.accX.rawValue]) ?? "0")!
        let accy = Float(keyRows[csvKeys.accY.rawValue] ?? "0")!
        let accz = Float(keyRows[csvKeys.accZ.rawValue] ?? "0")!
        let acc = [accx,accy,accz]
        
//        let magx = Float(_keyRows[csvKeys.magx.rawValue]!)!
//        let magy = Float(_keyRows[csvKeys.magy.rawValue]!)!
        let magz = Float(keyRows[csvKeys.magZ.rawValue] ?? "0")!
//        let mag = [magx,magy,magz]
        
        let shock = UInt8(keyRows[csvKeys.shock.rawValue] ?? "0")!
        
        DispatchQueue.main.async {
            // Main Threadで実行する
            self.dummyOrphe.setSensorValues(quat: quat, euler: euler, acc: acc, gyro: gyro, mag: UInt16(magz), shock: shock)
            NotificationCenter.default.post(name: .OrpheDidUpdateSensorData, object: nil, userInfo: [OrpheDataUserInfoKey:self.dummyOrphe, OrpheUpdatedTransmissionOptionInfoKey:TransmissionOption.standard])
        }
        
        //row count
        self.currentRow += 1
        if currentRow == csv.rows.count {
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
        let time = Double(csv.keyedRows![currentRow-1][csvKeys.timestamp.rawValue]!)!
        let nextTime = Double(csv.keyedRows![currentRow][csvKeys.timestamp.rawValue]!)!
        let delayTime = nextTime - time
        let popTime = DispatchTime.now() + delayTime //0.0023引いているのはちょっと短くしないと５hzくらい遅くなる
        DispatchQueue.global().asyncAfter(deadline: popTime,  execute: {
            self.updateSensorValues()
        })
        
    }
    
}
