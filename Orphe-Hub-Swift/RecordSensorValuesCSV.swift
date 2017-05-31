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
    
    @objc func OrpheDidUpdateSensorDataCustomised(notification: Notification){
        guard let userInfo = notification.userInfo else {return}
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        if orphe.side != side {
            return
        }
        
        if isRecording {
            let sendingType = userInfo[OrpheUpdatedSendingTypeInfoKey] as! SendingType
            let sensorKind = userInfo[OrpheUpdatedSenorKindInfoKey] as! SensorKind
            let axisNumber = Int(userInfo[OrpheUpdatedAxisInfoKey] as! UInt8)
            
            let receiveTime = Date()
            
            //最初のやつ
            if recordText == "" {
                recordText = "time"
                
                
                //---受け取ってるやつだけ表示する場合の処理未完成---
//                var sensorName = ""
//                switch sensorKind {
//                case .quat:
//                    sensorName = "quat"
//                case .euler:
//                    sensorName = "euler"
//                case .acc:
//                    sensorName = "acc"
//                case .gyro:
//                    sensorName = "gyro"
//                }
//                
//                let axes = ["x","y","z"]
//                switch sendingType {
//                case .t_4b_50h,
//                     .t_2b_100h,
//                     .t_2b_150h,
//                     .t_1b_300h,
//                     .standard:
//                    for a in axes{
//                        recordText += ","+sensorName+" "+a
//                    }
//                    
//                case .t_2b_400h_1a,
//                     .t_4b_200h_1a:
//                    recordText += ","+sensorName+" "+axes[axisNumber]
//                    break
//                    
//                case .t_2b_200h_2a,
//                     .t_1b_400h_2a:
//                    switch axisNumber {
//                    case 0:
//                        recordText += ","+sensorName+" "+axes[0]
//                        recordText += ","+sensorName+" "+axes[1]
//                    case 1:
//                        recordText += ","+sensorName+" "+axes[1]
//                        recordText += ","+sensorName+" "+axes[2]
//                    case 2:
//                        recordText += ","+sensorName+" "+axes[2]
//                        recordText += ","+sensorName+" "+axes[0]
//                    default:
//                        break
//                    }
//                    break
//                }
                
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
            
            //数値の追加
            var array = [[Float]]()
            switch sensorKind {
            case .quat:
                array = orphe.getQuatArray()
            case .euler:
                array = orphe.getEulerArray()
            case .acc:
                array = orphe.getAccArray()
            case .gyro:
                array = orphe.getGyroArray()
            case .mag:
                array = orphe.getMagArray()
            }
            
            
            let bleInterval = 0.050 //50ms
            let timeInterval = bleInterval/Double(array.count)
            var index:Double = 0
            for value in array {
                let time = receiveTime.addingTimeInterval(timeInterval*index-bleInterval)
                index += 1
                recordText += format.string(from: time)
                for q in value {
                    recordText += "," + String(q)
                }
                recordText += "\n"
            }
        }
    }
    
    
    
}
