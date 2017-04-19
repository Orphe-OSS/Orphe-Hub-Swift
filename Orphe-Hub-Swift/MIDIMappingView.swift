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
                if msMapper == nil{
                    msMapper = MIDISensorMapper(orphe: orphe!)
                }
                else{
                    msMapper!.orphe = orphe!
                }
            }
        }
    }
    var msMapper:MIDISensorMapper?{
        didSet{
            updateUIValues()
        }
    }
    
    
    @IBOutlet weak var inputMinValueTextField: NSTextField!
    @IBOutlet weak var inputMaxValueTextField: NSTextField!
    @IBOutlet weak var smoothValueTextField: NSTextField!
    
    @IBOutlet weak var controlNumTextField: NSTextField!
    @IBOutlet weak var outputMinTextField: NSTextField!
    @IBOutlet weak var outputMaxTextField: NSTextField!
    
    @IBOutlet weak var invertCheckButton: NSButton!
    
    
    //Quat&EulerView

    @IBOutlet weak var QuatView: NSView!
    @IBOutlet weak var EulerView: NSView!
    var QuatSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:4)
    var EulerSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:3)
    
    //===SelectedData===
    //SelectedDataView
    @IBOutlet weak var selectedDataView: NSView!
    var selectedDataSubView:LabelGraphView!
    
    //PullDown式データ表示
    @IBOutlet weak var selectDataPopUp: NSPopUpButton!
    @IBAction func selectDataPopUpAction(_ sender: Any) {
        selectDataPopUp.title = (selectDataPopUp.selectedItem?.title)!
        msMapper?.sensorKind = SensorKind(rawValue: (selectDataPopUp.selectedItem?.title)!)!
        updateUIValues()
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
        for i in 0..<QuatSubView.count {
            //LEFT
            QuatSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(QuatView.bounds.height) - 25*(i+1), width: 200, height: 25))
            QuatView.addSubview(QuatSubView[i])
        }
        //----------Euler----------
        for i in 0..<EulerSubView.count {
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
    
    func updateUIValues(){
        guard let msMapper = self.msMapper else {
            return
        }
        inputMinValueTextField.stringValue = String(msMapper.minValue)
        inputMaxValueTextField.stringValue = String(msMapper.maxValue)
        smoothValueTextField.stringValue = String(msMapper.smooth)
        controlNumTextField.stringValue = String(msMapper.controlNumber)
        outputMinTextField.stringValue = String(msMapper.outputMinValue)
        outputMaxTextField.stringValue = String(msMapper.outputMaxValue)
        
        selectDataPopUp.title = msMapper.sensorKind.rawValue
        midiStatusPopUp.title = msMapper.midiStatus.rawValue
    }
    
    @IBAction func smoothValueTextFieldInput(_ sender: NSTextField) {
        msMapper?.smooth = sender.integerValue
    }
    
    @IBAction func minValueTextFieldInput(_ sender: NSTextField) {
        msMapper?.minValue = sender.doubleValue
    }
    
    @IBAction func maxValueTextFieldInput(_ sender: NSTextField) {
        msMapper?.maxValue = sender.doubleValue
    }
    
    @IBAction func outputMinValueTextFieldInput(_ sender: NSTextField) {
        msMapper?.outputMinValue = sender.doubleValue
    }
    
    @IBAction func outputMaxValueTextFieldInput(_ sender: NSTextField) {
        msMapper?.outputMaxValue = sender.doubleValue
    }
    
    
    @IBAction func controlNumberTextFieldInput(_ sender: NSTextField) {
        msMapper?.controlNumber = UInt8(sender.integerValue)
    }
    
    @IBAction func midiStatusPopUpAction(_ sender: Any) {
        midiStatusPopUp.title = (midiStatusPopUp.selectedItem?.title)!
        msMapper?.midiStatus = MIDIStatus(rawValue: midiStatusPopUp.selectedItem!.title)!
        updateUIValues()
    }
    
    @IBAction func invertCheckButtonAction(_ sender: NSButton) {
        msMapper?.isInvert = sender.state == 1
    }
    
    
    func orpheDidUpdateSensorData(orphe: ORPData) {
        if orphe != self.orphe { return }
        
        //-----------Quat--------------
        for (i, q) in orphe.getQuat().enumerated() {
            QuatSubView[i].textSubView.string = "\(i):" + String(format: "%.3f", q)
            QuatSubView[i].setGraphWidth(CGFloat(q*100))
        }
        //----------Euler----------
        for (i, e) in orphe.getEuler().enumerated() {
            EulerSubView[i].textSubView.string = "\(i):" + String(format: "%.3f", e)
            EulerSubView[i].setGraphWidth( CGFloat(e*100))
        }
        
        //----SelectedData----
        selectedDataSubView.textSubView.string = String(format: "%.3f", msMapper!.getSelectedSensorValue())
        selectedDataSubView.setGraphValue(CGFloat(msMapper!.getNormalizedSelectedSensorValue()))
        
        outputValueGraph.textSubView.string = String(format: "%.3f", msMapper!.currentOutputValue)
        outputValueGraph.setGraphValue(CGFloat(msMapper!.getNormalizedCurrnetValue()))
    }
    
}
