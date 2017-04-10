//
//  MIDIMappingView.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/04/10.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa
import Orphe

class MIDIMappingView : NSView{
    
    weak var orphe:ORPData?{
        didSet{
            if orphe != nil{
                sensorDataTuner = SensorDataTuner(orphe: orphe!)
            }
        }
    }
    var sensorDataTuner:SensorDataTuner?
    
    //Quat&EulerView
    @IBOutlet weak var QuatView: NSView!
    @IBOutlet weak var EulerView: NSView!
    var QuatSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:numQuat)
    var EulerSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:numEuler)
    
    //===SelectedData===
    //SelectedDataView
    @IBOutlet weak var selectedDataView: NSView!
    var selectedDataSubView:LabelGraphView!
    
    //PullDown式データ表示
    @IBOutlet weak var selectDataPopUp: NSPopUpButton!
    @IBAction func selectDataPopUpAction(_ sender: Any) {
        selectDataPopUp.title = (selectDataPopUp.selectedItem?.title)!
        sensorDataTuner?.sensorKind = SensorKind(rawValue: (selectDataPopUp.selectedItem?.title)!)!
    }
    
    @IBOutlet weak var midiStatusPopUp: NSPopUpButton!
    
    @IBOutlet weak var outputValueGraph: LabelGraphView!
    
    class func newMIDIMappingView() -> MIDIMappingView {
        
        var topLevelObjects: NSArray? = []
        let nib = NSNib(nibNamed: "MIDIMappingView", bundle: Bundle.main)!
        nib.instantiate(withOwner: self, topLevelObjects: &topLevelObjects!)
        
        var view: MIDIMappingView!
        
        for object: Any in topLevelObjects! {
            if let obj = object as? MIDIMappingView {
                view = obj
                break
            }
        }
        
        view.commonInit()
        
        return view
    }
    
    func commonInit(){
        //PopUpButtonのリストをリセット
        var skArray = [String]()
        for sk in SensorKind.cases{
            skArray.append(sk.rawValue)
        }
        selectDataPopUp.removeAllItems()
        selectDataPopUp.addItems(withTitles: skArray)
        
        var msArray = [String]()
        for ms in MIDIStatus.cases{
            msArray.append(ms.rawValue)
        }
        midiStatusPopUp.removeAllItems()
        midiStatusPopUp.addItems(withTitles: msArray)
        
        //----------Quat----------
        for i in 0..<numQuat {
            //LEFT
            QuatSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(QuatView.bounds.height) - 25*(i+1), width: 200, height: 25))
            QuatView.addSubview(QuatSubView[i])
        }
        //----------Euler----------
        for i in 0..<numEuler {
            //LEFT
            EulerSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(EulerView.bounds.height) - 25*(i+1), width: 200, height: 25))
            EulerView.addSubview(EulerSubView[i])
        }
        
        //----SelectedData----
        selectedDataSubView = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(selectedDataView.bounds.height) - 25, width: 200, height: 25))
        selectedDataView.addSubview(selectedDataSubView)
        
        
        outputValueGraph.wantsLayer = true
        outputValueGraph.layer?.borderWidth = 1.0
        QuatView.wantsLayer = true
        QuatView.layer?.borderWidth = 1.0
        EulerView.wantsLayer = true
        EulerView.layer?.borderWidth = 1.0
        selectedDataView.wantsLayer = true
        selectedDataView.layer?.borderWidth = 1.0
    }
    
    @IBAction func smoothValueTextFieldInput(_ sender: NSTextField) {
        sensorDataTuner?.smooth = sender.integerValue
    }
    
    @IBAction func minValueTextFieldInput(_ sender: NSTextField) {
        sensorDataTuner?.minValue = sender.doubleValue
    }
    
    @IBAction func maxValueTextFieldInput(_ sender: NSTextField) {
        sensorDataTuner?.maxValue = sender.doubleValue
    }
    
    @IBAction func controlNumberTextFieldInput(_ sender: NSTextField) {
        sensorDataTuner?.controlNumber = UInt8(sender.integerValue)
    }
    
    @IBAction func midiStatusPopUpAction(_ sender: Any) {
        midiStatusPopUp.title = (midiStatusPopUp.selectedItem?.title)!
        sensorDataTuner?.midiStatus = MIDIStatus(rawValue: midiStatusPopUp.selectedItem!.title)!
    }
    
    func orpheDidUpdateSensorData(orphe: ORPData) {
        if orphe != self.orphe { return }
        
        //-----------Quat--------------
        for (i, q) in orphe.getQuat().enumerated() {
            QuatSubView[i].textSubView.string = "\(i):" + String(format: "%.3f", q)
            QuatSubView[i].setGratphWidth(CGFloat(q*100))
        }
        //----------Euler----------
        for (i, e) in orphe.getEuler().enumerated() {
            EulerSubView[i].textSubView.string = "\(i):" + String(format: "%.3f", e)
            EulerSubView[i].setGratphWidth( CGFloat(e*100))
        }
        
        //----SelectedData----
        selectedDataSubView.textSubView.string = String(format: "%.3f", sensorDataTuner!.getSelectedSensorValue())
        selectedDataSubView.setGraphValue(CGFloat(sensorDataTuner!.getNormalizedSelectedSensorValue()))
        
        outputValueGraph.textSubView.string = String(format: "%.3f", sensorDataTuner!.currentOutputValue)
        outputValueGraph.setGraphValue(CGFloat(sensorDataTuner!.getNormalizedCurrnetValue()))
    }
    
}
