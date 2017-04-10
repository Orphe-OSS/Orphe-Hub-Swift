//
//  ViewController.swift
//  OrpheExample_macOS
//
//  Created by no new folk studio Inc. on 2016/12/21.
//  Copyright © 2016 no new folk studio Inc. All rights reserved.
//

import Cocoa
import Orphe
import OSCKit

let numData = 15
let numQuat = 4
let numEuler = 3

class ViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var oscHostTextField: NSTextField!
    @IBOutlet weak var oscSenderTextField: NSTextField!
    @IBOutlet weak var oscReceiverTextField: NSTextField!
    @IBOutlet var oscLogTextView: NSTextView!
    
    var sensorDataTuner = [SensorDataTuner]()
    
    //Quat&EulerView
    @IBOutlet weak var leftQuatView: NSView!
    @IBOutlet weak var rightQuatView: NSView!
    @IBOutlet weak var leftEulerView: NSView!
    @IBOutlet weak var rightEulerView: NSView!
    
    //PullDown式データ表示
    @IBOutlet weak var dataPopUp: NSPopUpButton!
    @IBAction func setDataTitle(_ sender: Any) {
        dataPopUp.title = (dataPopUp.selectedItem?.title)!
        for std in sensorDataTuner{
            if std.orphe.side == .left{
                std.sensorKind = SensorKind(rawValue: (dataPopUp.selectedItem?.title)!)!
            }
        }
    }
    
    //SelectedDataView
    @IBOutlet weak var leftSelectedDataView: NSView!
    @IBOutlet weak var rightSelectedDataView: NSView!
    
    @IBAction func switchToOppositeSide(_ sender: Any) {
        for (index, _) in ORPManager.sharedInstance.availableORPDataArray.enumerated(){
            let orphe = ORPManager.sharedInstance.connectedORPDataArray[index]
            orphe.switchToOppositeSide()
        }
    }
    
    var leftQuatSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:numQuat)
    var rightQuatSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:numQuat)
    
    var leftEulerSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:numEuler)
    var rightEulerSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:numEuler)
    
    //===SelectedData===
    var leftSelectedDataSubView = LabelGraphView()
    var rightSelectedDataSubView = LabelGraphView()
    
    
    var rssiTimer: Timer?
    
    var leftGesture = ""
    var rightGesture = ""
    
    let dataParamItem:[String] = ["0","1","2","3"]
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.allowsTypeSelect = false
        
        //PopUpButtonのリストをリセット
        dataPopUp.removeAllItems()
        dataPopUp.addItems(withTitles: SensorDataTuner.sensorKindArray)
        
        //AllDataText
        
        //----------Quat----------
        for i in 0..<numQuat {
            //LEFT
            leftQuatSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(leftQuatView.bounds.height) - 25*(i+1), width: 200, height: 25))
            leftQuatView.addSubview(leftQuatSubView[i])
            //RIGHT
            rightQuatSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(rightQuatView.bounds.height) - 25*(i+1), width: 200, height: 25))
            rightQuatView.addSubview(rightQuatSubView[i])
        }
        //----------Euler----------
        for i in 0..<numEuler {
            //LEFT
            leftEulerSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(leftEulerView.bounds.height) - 25*(i+1), width: 200, height: 25))
            leftEulerView.addSubview(leftEulerSubView[i])
            //RIGHT
            rightEulerSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(rightEulerView.bounds.height) - 25*(i+1), width: 200, height: 25))
            rightEulerView.addSubview(rightEulerSubView[i])
        }
        //----------Acc----------
        
        //----------Gyro----------
        
        //----------Mag----------
        
        //----------Quat----------
        
        //----------Shock----------
        
        //----SelectedData----
        leftSelectedDataSubView = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(rightSelectedDataView.bounds.height) - 25, width: 200, height: 25))
        leftSelectedDataView.addSubview(leftSelectedDataSubView)
        rightSelectedDataSubView = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(rightSelectedDataView.bounds.height) - 25, width: 200, height: 25))
        rightSelectedDataView.addSubview(rightSelectedDataSubView)
        
        
        ORPManager.sharedInstance.delegate = self
        ORPManager.sharedInstance.isEnableAutoReconnection = false
        ORPManager.sharedInstance.startScan()
        
        rssiTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.readRSSI), userInfo: nil, repeats: true)
        
        //OSC view
        OSCManager.sharedInstance.delegate = self
        if !OSCManager.sharedInstance.startReceive(){
            oscReceiverTextField.textColor = .red
        }
        oscHostTextField.stringValue = OSCManager.sharedInstance.clientHost
        oscSenderTextField.stringValue = String(OSCManager.sharedInstance.clientPort)
        oscReceiverTextField.stringValue = String(OSCManager.sharedInstance.serverPort)
        
        //MIDI
        MIDIManager.sharedInstance.initMIDI()
    }
    
    override func viewDidLayout() {
        leftQuatView.layer?.borderWidth = 1.0
        rightQuatView.layer?.borderWidth = 1.0
        leftEulerView.layer?.borderWidth = 1.0
        rightEulerView.layer?.borderWidth = 1.0
        leftSelectedDataView.layer?.borderWidth = 1.0
        rightSelectedDataView.layer?.borderWidth = 1.0
    }
    
    override var representedObject: Any? {
        didSet {
            
        }
    }
    
    func updateCellsState(){
        for (index, orp) in ORPManager.sharedInstance.availableORPDataArray.enumerated(){
            for (columnNum, _) in tableView.tableColumns.enumerated(){
                if let cell = tableView.view(atColumn: columnNum, row: index, makeIfNecessary: true) as? NSTableCellView{
                    if orp.state() == .connected{
                        cell.textField?.textColor = NSColor.yellow
                        cell.textField?.backgroundColor = NSColor.darkGray
                    }
                    else{
                        cell.textField?.textColor = NSColor.black
                        cell.textField?.backgroundColor = NSColor.white
                    }
                }
            }
            
        }
    }
    
//    override func keyDown(with theEvent: NSEvent) {
//        super.keyDown(with: theEvent)
//        if let lightNum:UInt8 = UInt8(theEvent.characters!){
//            for orp in ORPManager.sharedInstance.connectedORPDataArray{
//                orp.triggerLight(lightNum: lightNum)
//            }
//        }
//    }
    
//    @IBAction func oscHostTextFieldInput(_ sender: Any) {
//        print(sender)
//        
//    }
    
    @IBAction func oscHostTextFieldInput(_ sender: NSTextField) {
        OSCManager.sharedInstance.clientHost = sender.stringValue
        print(sender.stringValue)
    }
    
    @IBAction func oscSenderPortTextFieldInput(_ sender: NSTextField) {
        OSCManager.sharedInstance.clientPort = sender.integerValue
    }
    
    @IBAction func oscReceiverPortTextFieldInput(_ sender: NSTextField) {
        OSCManager.sharedInstance.stopReceive()
        OSCManager.sharedInstance.serverPort = sender.integerValue
        if !OSCManager.sharedInstance.startReceive(){
            oscReceiverTextField.textColor = .red
        }
        else{
            oscReceiverTextField.textColor = .black
        }
    }
    
}

//MARK: - NSTableViewDelegate
extension  ViewController: NSTableViewDelegate{
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let cellIdentifier: String = "NameCell"
        
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            if tableColumn == tableView.tableColumns[0] {
                cell.textField?.stringValue = ORPManager.sharedInstance.availableORPDataArray[row].name
                cell.textField?.drawsBackground = true
            }
            else if tableColumn == tableView.tableColumns[1] {
                cell.textField?.stringValue = "0"
                cell.textField?.drawsBackground = true
            }
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow != -1 {
            let orp = ORPManager.sharedInstance.availableORPDataArray[tableView.selectedRow]
            if orp.state() == .disconnected{
                ORPManager.sharedInstance.connect(orphe: orp)
            }
            else{
                ORPManager.sharedInstance.disconnect(orphe: orp)
            }
        }
    }
    
}

//MARK: - NSTableViewDataSource
extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return ORPManager.sharedInstance.availableORPDataArray.count
    }
    
    
}

//MARK: - ORPManagerDelegate
extension  ViewController: ORPManagerDelegate{
    
    func orpheDidUpdateBLEState(state:CBCentralManagerState){
        PRINT("didUpdateBLEState", state)
        switch state {
        case .poweredOn:
            ORPManager.sharedInstance.startScan()
        default:
            break
        }
    }
    
    func orpheDidUpdateRSSI(orphe:ORPData){
        if let index = ORPManager.sharedInstance.availableORPDataArray.index(of: orphe){
            if let cell = tableView.view(atColumn: 1, row: index, makeIfNecessary: false) as? NSTableCellView{
                cell.textField?.stringValue = String(describing: orphe.RSSI)
            }
        }
    }
    
    func orpheDidDiscoverOrphe(orphe:ORPData){
        PRINT("didDiscoverOrphe")
        tableView.reloadData()
        updateCellsState()
    }
    
    func orpheDidDisappearOrphe(orphe:ORPData){
        PRINT("didDisappearOrphe")
        tableView.reloadData()
        updateCellsState()
    }
    
    func orpheDidFailToConnect(orphe:ORPData){
        PRINT("didFailToConnect")
        tableView.reloadData()
        updateCellsState()
    }
    
    func orpheDidDisconnect(orphe:ORPData){
        PRINT("didDisconnect")
        tableView.reloadData()
        updateCellsState()
        
        for (index, sdt) in sensorDataTuner.enumerated(){
            if sdt.orphe == orphe {
                sensorDataTuner.remove(at: index)
            }
        }
    }
    
    func orpheDidConnect(orphe:ORPData){
        PRINT("didConnect")
        tableView.reloadData()
        updateCellsState()
        
        orphe.setScene(.sceneSDK)
        orphe.setGestureSensitivity(.high)
        
        let std = SensorDataTuner(orphe: orphe)
        if orphe.side == .left{
            std.midiStatus = .pitchBend
        }
        else{
            std.midiStatus = .controlChange
        }
        sensorDataTuner.append(std)
        
    }
    
    func orpheDidUpdateOrpheInfo(orphe:ORPData){
        PRINT("didUpdateOrpheInfo")
    }
    
    func readRSSI(){
        for orp in ORPManager.sharedInstance.connectedORPDataArray {
            orp.readRSSI()
        }
    }
    
    func orpheDidUpdateSensorData(orphe: ORPData) {
        
        
        //-----------Quat--------------
        for (i, q) in orphe.getQuat().enumerated() {
            if orphe.side == .left {
                leftQuatSubView[i].textSubView.string = "\(i):" + String(format: "%.3f", q)
                leftQuatSubView[i].setGratphWidth(100, Int(q*100))
            }else{
                rightQuatSubView[i].textSubView.string = "\(i):" + String(format: "%.3f", q)
                rightQuatSubView[i].setGratphWidth(100, Int(q*100))
            }
        }
        //----------Euler----------
        for (i, e) in orphe.getEuler().enumerated() {
            if orphe.side == .left {
                leftEulerSubView[i].textSubView.string = "\(i):" + String(format: "%.3f", e)
                leftEulerSubView[i].setGratphWidth(100, Int(e*100))
            }else{
                rightEulerSubView[i].textSubView.string = "\(i):" + String(format: "%.3f", e)
                rightEulerSubView[i].setGratphWidth(100, Int(e*100))
            }
        }
        //----------Acc----------
        
        //----------Gyro----------
        
        //----------Mag----------
        
        //----------Quat----------
        
        //----------Shock----------
        
        //----SelectedData----
        for sdt in sensorDataTuner{
            if sdt.orphe == orphe{
                if orphe.side == .left {
                    leftSelectedDataSubView.textSubView.string = String(format: "%.3f", sdt.getSelectedSensorValue())
                    leftSelectedDataSubView.setGratphWidth(100, Int(sdt.getNormalizedSelectedSensorValue()*100))
                }else{ //RIGHT
                    rightSelectedDataSubView.textSubView.string = String(format: "%.3f", sdt.getSelectedSensorValue())
                    rightSelectedDataSubView.setGratphWidth(100, Int(sdt.getNormalizedSelectedSensorValue()*100))
                }
            }
        }
    }
    
    func orpheDidCatchGestureEvent(gestureEvent:ORPGestureEventArgs, orphe:ORPData) {
        let side = orphe.side
        let kind = gestureEvent.getGestureKindString() as String
        let power = gestureEvent.getPower()
        if side == ORPSide.left {
            leftGesture = "Gesture: " + kind + "\n"
            leftGesture += "power: " + String(power)
        }
        else{
            rightGesture = "Gesture: " + kind + "\n"
            rightGesture += "power: " + String(power)
        }
    }
}

extension ViewController: OSCManagerDelegate{
    func oscDidReceiveMessage(message:String) {
        oscLogTextView.string = message + "\n" + oscLogTextView.string!
    }
}
