//
//  RecordSensorValuesCSV.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/05/30.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Foundation
import Orphe

class RecordSensorValuesCSV {
    
    var isRecording = false
    var recordText = ""
    var format = DateFormatter()
    var side = ORPSide.left
    
    init(side:ORPSide) {
        self.side = side
        NotificationCenter.default.addObserver(self, selector:  #selector(RecordSensorValuesCSV.OrpheDidUpdateSensorDataCustomised(notification:)), name: .OrpheDidUpdateSensorDataCustomised, object: nil)
        
        format.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
    }
    
    func startRecording(){
        isRecording = true
        recordText = ""
    }
    
    func stopRecording(){
        isRecording = false
    }
    
    func valuesToCSV(orphe:ORPData, sensorKind:SensorKind, receiveTime:Date)->String{
        //数値の追加
        var text = ""
        var arrayArray = [[Float]]()
        switch sensorKind {
        case .quat:
            arrayArray = orphe.getQuatArray()
        case .euler:
            arrayArray = orphe.getEulerArray()
        case .acc:
            arrayArray = orphe.getAccArray()
        case .gyro:
            arrayArray = orphe.getGyroArray()
        case .mag:
            arrayArray = orphe.getMagArray()
        }
        
        
        let bleInterval = 0.050 //50ms
        let timeInterval = bleInterval/Double(arrayArray.count)
        var index:Double = 0
        for array in arrayArray {
//            let time = receiveTime.addingTimeInterval(timeInterval*index-bleInterval)
            index += 1
            text += format.string(from: receiveTime)
            for value in array {
                text += "," + String(value)
            }
            
            if arrayArray.count > 1 { //TODO: 暫定処理。複数のセンサを高サンプリングレートで送る場合には対応できない。
                text += "\n"
            }
        }
        
        return text
    }
    
    @objc func OrpheDidUpdateSensorDataCustomised(notification: Notification){
        guard let userInfo = notification.userInfo else {return}
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        if orphe.side != side {
            return
        }
        
        if isRecording {
            let sendingType = userInfo[OrpheUpdatedSendingTypeInfoKey] as! SendingType
            
            let receiveTime = Date()
            
            if sendingType == .standard{
                //最初のやつ
                if recordText == "" {
                    recordText = "time, quat w, quat x, quat y, quat z,euler x, euler y, euler z,acc x, acc y, acc z,gyro x, gyro y, gyro z,mag x, mag y, mag z"
                    recordText += "\n"
                }
                
                recordText += valuesToCSV(orphe: orphe, sensorKind: .quat, receiveTime: receiveTime)
                recordText += valuesToCSV(orphe: orphe, sensorKind: .euler, receiveTime: receiveTime)
                recordText += valuesToCSV(orphe: orphe, sensorKind: .acc, receiveTime: receiveTime)
                recordText += valuesToCSV(orphe: orphe, sensorKind: .gyro, receiveTime: receiveTime)
                recordText += valuesToCSV(orphe: orphe, sensorKind: .mag, receiveTime: receiveTime)
                recordText += "\n"
            }
            else{
                let sensorKind = userInfo[OrpheUpdatedSenorKindInfoKey] as! SensorKind
                let axisNumber = Int(userInfo[OrpheUpdatedAxisInfoKey] as! UInt8)
                
                //最初のやつ
                if recordText == "" {
                    recordText = "time"
                    
                    switch sensorKind {
                    case .quat:
                        recordText += ",quat w, quat x, quat y, quat z"
                        
                    case .euler:
                        recordText += ",euler x, euler y, euler z"
                    case .acc:
                        recordText += ",acc x, acc y, acc z"
                    case .gyro:
                        recordText += ",gyro x, gyro y, gyro z"
                    case .mag:
                        recordText += ",mag x, mag y, mag z"
                    }
                    recordText += "\n"
                }
                
                recordText += valuesToCSV(orphe: orphe, sensorKind: sensorKind, receiveTime: receiveTime)
                recordText += "\n"
            }
            
        }
    }
    
    
    
}
