//
//  SensorVisualizerView.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/01.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa
import Orphe
import RxSwift
import RxCocoa

class SensorVisualizerView:NSView{
    
    @IBOutlet weak var quatGraph: MultiLineGraphView!
    @IBOutlet weak var eulerGraph: MultiLineGraphView!
    @IBOutlet weak var accGraph: MultiLineGraphView!
    @IBOutlet weak var gyroGraph: MultiLineGraphView!
    @IBOutlet weak var magGraph: MultiLineGraphView!
    
    @IBOutlet weak var gestureLabel: NSTextField!
    @IBOutlet weak var frequencyLabel: NSTextField!
    
    @IBOutlet weak var sideLabel: NSTextField!
    
    var updateTimer:Timer?
    
    var disposeBag = DisposeBag()
    
    var bleFreq = SensorFreqencyCalculator()
    var qFreq = SensorFreqencyCalculator()
    var aFreq = SensorFreqencyCalculator()
    var gFreq = SensorFreqencyCalculator()
    var eFreq = SensorFreqencyCalculator()
    
    var side:ORPSide = .left{
        didSet{
            if side == .right {
                sideLabel.stringValue = "RIGHT"
            }
        }
    }
    var orphe:ORPData?
    
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
        quatGraph.setAxis(["X","Y","Z","W"])
        accGraph.setAxis(["X","Y","Z"])
        gyroGraph.setAxis(["X","Y","Z"])
        eulerGraph.setAxis(["X","Y","Z"])
        magGraph.setAxis(["X","Y","Z"])
    }
    
    func updateSensorValues(orphe:ORPData){
        updateFreqCalculator(orphe: orphe)
        updateSensorGraph(orphe: orphe)
    }
    
    func updateSensorGraph(orphe:ORPData){
        for array in orphe.quatArray {
            for (i ,val) in array.enumerated(){
                quatGraph.lineGraphLabelArray[i].lineGraphView.addValue(CGFloat(val))
            }
        }
        for array in orphe.normalizedAccArray {
            for (i ,val) in array.enumerated(){
                accGraph.lineGraphLabelArray[i].lineGraphView.addValue(CGFloat(val))
            }
        }
        for array in orphe.normalizedGyroArray {
            for (i ,val) in array.enumerated(){
                gyroGraph.lineGraphLabelArray[i].lineGraphView.addValue(CGFloat(val))
            }
        }
        for array in orphe.normalizedEulerArray {
            for (i ,val) in array.enumerated(){
                eulerGraph.lineGraphLabelArray[i].lineGraphView.addValue(CGFloat(val))
            }
        }
        for array in orphe.normalizedMagArray {
            for (i ,val) in array.enumerated(){
                magGraph.lineGraphLabelArray[i].lineGraphView.addValue(CGFloat(val))
            }
        }
    }
    
    func updateFreqCalculator(orphe:ORPData){
        bleFreq.update()
        for array in orphe.quatArray {
            qFreq.updateValue2(value: array[0])
        }
        for array in orphe.accArray {
            aFreq.updateValue2(value: array[0])
        }
        for array in orphe.gyroArray {
            gFreq.updateValue2(value: array[0])
        }
        for array in orphe.eulerArray {
            eFreq.updateValue2(value: array[0])
        }
        
        if qFreq.isFreqValueUpdated{
            var text = ""
            text += ": " + String(format: "%.2f",bleFreq.freq) + "Hz\n"
            text += ": " + String(format: "%.2f",qFreq.freq) + "Hz\n"
            text += ": " + String(format: "%.2f",eFreq.freq) + "Hz\n"
            text += ": " + String(format: "%.2f",aFreq.freq) + "Hz\n"
            text += ": " + String(format: "%.2f",gFreq.freq) + "Hz\n"
            frequencyLabel.stringValue = text
        }
    }
    
    func sensorValueTextForLabel(orphe:ORPData, sensorKind:SensorKind)->String{
        var text = ""
        var sensorStr = ""
        var arrayArray = [[Float]]()
        if sensorKind == .acc{
            sensorStr = "Acc"
            arrayArray = orphe.accArray
        }
        else if sensorKind == .gyro{
            sensorStr = "Gyro"
            arrayArray = orphe.gyroArray
        }
        else if sensorKind == .euler{
            sensorStr = "Euler"
            arrayArray = orphe.eulerArray
        }
        else if sensorKind == .quat{
            sensorStr = "Quat"
            arrayArray = orphe.quatArray
        }
        else if sensorKind == .mag{
            sensorStr = "Mag"
            arrayArray = orphe.magArray
        }
        for (j, array) in arrayArray.enumerated() {
            for (i, a) in array.enumerated() {
                text += sensorStr + "\(j)\(i): "+String(a) + "\n"
            }
        }
        return text
    }
    
    func startUpdateGraphView(){
        if updateTimer != nil{
            if updateTimer!.isValid{
                return
            }
        }
        updateTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.updateDisplay), userInfo: nil, repeats: true)
    }
    
    func stopUpdateGraphView(){
        updateTimer?.invalidate()
    }
    
    func isActive()->Bool{
        return updateTimer?.isValid ?? false
    }
    
    func updateDisplay(tm: Timer){
        
        if let orphe = orphe{
            quatGraph.updateDisplay()
            eulerGraph.updateDisplay()
            accGraph.updateDisplay()
            gyroGraph.updateDisplay()
            magGraph.updateDisplay()
            
            //x,y,z,wの順。他のグラフと色を合わせるため入れ替え
            let quat = [orphe.getQuat()[3],orphe.getQuat()[0],orphe.getQuat()[1],orphe.getQuat()[2]]
            quatGraph.updateLabel(values: quat)
            eulerGraph.updateLabel(values: orphe.getEuler())
            accGraph.updateLabel(values: orphe.getAcc())
            gyroGraph.updateLabel(values: orphe.getGyro())
            magGraph.updateLabel(values: [0,0,orphe.getMag()])
        }
        
    }
    
    func initFreqCalculators(){
        qFreq.initValues()
        eFreq.initValues()
        aFreq.initValues()
        gFreq.initValues()
    }
}
