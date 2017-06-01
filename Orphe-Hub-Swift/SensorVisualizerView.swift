//
//  SensorVisualizerView.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/01.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa
import Orphe

class SensorVisualizerView:NSView{
    
    @IBOutlet weak var quatGraph: MultiLineGraphView!
    @IBOutlet weak var eulerGraph: MultiLineGraphView!
    @IBOutlet weak var accGraph: MultiLineGraphView!
    @IBOutlet weak var gyroGraph: MultiLineGraphView!
    
    @IBOutlet weak var sensorValueLabel: NSTextField!
    @IBOutlet weak var frequencyLabel: NSTextField!
    
    var bleFreq = SensorFreqencyCalculator()
    var qFreq = SensorFreqencyCalculator()
    var aFreq = SensorFreqencyCalculator()
    var gFreq = SensorFreqencyCalculator()
    var eFreq = SensorFreqencyCalculator()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    // Storyboard/xib から初期化はここから
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    // xibからカスタムViewを読み込んで準備する
    fileprivate func commonInit() {
        // MyCustomView.xib からカスタムViewをロードする
        let bundle = Bundle(for: type(of: self))
        let className = NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
        let nib = NSNib(nibNamed: className, bundle: bundle)!
        var topLevelObjects = NSArray()
        nib.instantiate(withOwner: self, topLevelObjects: &topLevelObjects)
        let views = (topLevelObjects as Array).filter { $0 is NSView }
        let view = views.first as! NSView
        addSubview(view)
        
        // カスタムViewのサイズを自分自身と同じサイズにする
        view.translatesAutoresizingMaskIntoConstraints = false
        let bindings = ["view": view]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                      options:NSLayoutFormatOptions(rawValue: 0),
                                                      metrics:nil,
                                                      views: bindings))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                      options:NSLayoutFormatOptions(rawValue: 0),
                                                      metrics:nil,
                                                      views: bindings))
        
    }
    
    func initSettings(){
        quatGraph.setLineNum(4)
        accGraph.setLineNum(3)
        gyroGraph.setLineNum(3)
        eulerGraph.setLineNum(3)
        
        quatGraph.layer?.backgroundColor = .black
        accGraph.layer?.backgroundColor = .black
        gyroGraph.layer?.backgroundColor = .black
        eulerGraph.layer?.backgroundColor = .black
    }
    
    func updateSensorValues(orphe:ORPData){
        updateFreqCalculator(orphe: orphe)
        updateSensorGraph(orphe: orphe)
        updateSensorValueLabel(orphe: orphe)
    }
    
    func updateSensorGraph(orphe:ORPData){
        
        for array in orphe.getQuatArray() {
            for (i ,val) in array.enumerated(){
                quatGraph.lineGraphArray[i].addValue(CGFloat(val))
            }
        }
        for array in orphe.getAccArray() {
            for (i ,val) in array.enumerated(){
                accGraph.lineGraphArray[i].addValue(CGFloat(val/Float(ORPAccRange._16.rawValue)))
            }
        }
        for array in orphe.getGyroArray() {
            for (i ,val) in array.enumerated(){
                gyroGraph.lineGraphArray[i].addValue(CGFloat(val/Float(ORPGyroRange._2000.rawValue)))
            }
        }
        for array in orphe.getEulerArray() {
            for (i ,val) in array.enumerated(){
                eulerGraph.lineGraphArray[i].addValue(CGFloat(val/Float(180)))
            }
        }
    }
    
    func updateSensorValueLabel(orphe:ORPData){
        var text = ""
        text += sensorValueTextForLabel(orphe:orphe, sensorKind:.quat)
        text += sensorValueTextForLabel(orphe:orphe, sensorKind:.euler)
        text += sensorValueTextForLabel(orphe:orphe, sensorKind:.acc)
        text += sensorValueTextForLabel(orphe:orphe, sensorKind:.gyro)
        text += sensorValueTextForLabel(orphe:orphe, sensorKind:.mag)
        sensorValueLabel.stringValue = "Sensor values\n\n" + text
    }
    
    func updateFreqCalculator(orphe:ORPData){
        bleFreq.update()
        for array in orphe.getQuatArray() {
            qFreq.updateValue2(value: array[0])
        }
        for array in orphe.getAccArray() {
            aFreq.updateValue2(value: array[0])
        }
        for array in orphe.getGyroArray() {
            gFreq.updateValue2(value: array[0])
        }
        for array in orphe.getEulerArray() {
            eFreq.updateValue2(value: array[0])
        }
        
        var text = ""
        text += "BLE freq: " + String(bleFreq.freq) + "Hz\n\n"
        text += "Quat freq: " + String(qFreq.freq) + "Hz\n\n"
        text += "Euler freq: " + String(eFreq.freq) + "Hz\n\n"
        text += "Acc freq: " + String(aFreq.freq) + "Hz\n\n"
        text += "Gyro freq: " + String(gFreq.freq) + "Hz\n\n"
        frequencyLabel.stringValue = text
    }
    
    func sensorValueTextForLabel(orphe:ORPData, sensorKind:SensorKind)->String{
        var text = ""
        var sensorStr = ""
        var arrayArray = [[Float]]()
        if sensorKind == .acc{
            sensorStr = "Acc"
            arrayArray = orphe.getAccArray()
        }
        else if sensorKind == .gyro{
            sensorStr = "Gyro"
            arrayArray = orphe.getGyroArray()
        }
        else if sensorKind == .euler{
            sensorStr = "Euler"
            arrayArray = orphe.getEulerArray()
        }
        else if sensorKind == .quat{
            sensorStr = "Quat"
            arrayArray = orphe.getQuatArray()
        }
        else if sensorKind == .mag{
            sensorStr = "Mag"
            arrayArray = orphe.getMagArray()
        }
        for (j, array) in arrayArray.enumerated() {
            for (i, a) in array.enumerated() {
                text += sensorStr + "\(j)\(i): "+String(a) + "\n"
            }
        }
        return text
    }
}
