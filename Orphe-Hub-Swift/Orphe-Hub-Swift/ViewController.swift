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
    @IBOutlet weak var leftSensorLabel: NSTextField!
    @IBOutlet weak var rightSensorLabel: NSTextField!
    
    @IBOutlet weak var oscHostTextField: NSTextField!
    @IBOutlet weak var oscSenderTextField: NSTextField!
    @IBOutlet weak var oscReceiverTextField: NSTextField!
    @IBOutlet var oscLogTextView: NSTextView!
    
    //Quat&EulerView
    @IBOutlet weak var leftQuatView: NSView!
    @IBOutlet weak var rightQuatView: NSView!
    @IBOutlet weak var leftEulerView: NSView!
    @IBOutlet weak var rightEulerView: NSView!
    
    //PullDown式データ表示
    @IBOutlet weak var dataPopUp: NSPopUpButton!
    @IBAction func setDataTitle(_ sender: Any) {
        dataPopUp.title = (dataPopUp.selectedItem?.title)!
    }
    @IBOutlet weak var dataParamPopUp: NSPopUpButton!
    @IBAction func setDataParamTitle(_ sender: Any) {
        dataParamPopUp.title = (dataParamPopUp.selectedItem?.title)!
    }
    
    //SelectedDataView
    @IBOutlet weak var leftDataView: NSView!
    @IBOutlet weak var rightDataView: NSView!
    
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
    
    //var leftDataSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:4)
    //var rightDataSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:4)
    var leftDataSubView = LabelGraphView()
    var rightDataSubView = LabelGraphView()
    
    
    var rssiTimer: Timer?
    
    var leftGesture = ""
    var rightGesture = ""
    
    let dataItem:[String] = ["Quat","Euler","Acc","Gyro","Mag","Shock"]
    let dataParamItem:[String] = ["0","1","2","3"]
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.allowsTypeSelect = false
        
        //PopUpButtonのリストをリセット
        dataPopUp.removeAllItems()
        dataPopUp.addItems(withTitles: dataItem)
        dataParamPopUp.removeAllItems()
        dataParamPopUp.addItems(withTitles: dataParamItem)
        
        //AllDataText
        leftSensorLabel.layer?.borderWidth = 2.0
        rightSensorLabel.layer?.borderWidth = 2.0
        
        //----------Quat----------
        leftQuatView.layer?.borderWidth = 1.0
        rightQuatView.layer?.borderWidth = 1.0
        for i in 0..<numQuat {
            //LEFT
            leftQuatSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(leftQuatView.bounds.height) - 25*(i+1), width: 200, height: 25))
            leftQuatView.addSubview(leftQuatSubView[i])
            //RIGHT
            rightQuatSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(rightQuatView.bounds.height) - 25*(i+1), width: 200, height: 25))
            rightQuatView.addSubview(rightQuatSubView[i])
        }
        //----------Euler----------
        leftEulerView.layer?.borderWidth = 1.0
        rightEulerView.layer?.borderWidth = 1.0
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
        leftDataView.layer?.borderWidth = 1.0
        leftDataSubView = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(rightDataView.bounds.height) - 25, width: 200, height: 25))
        leftDataView.addSubview(leftDataSubView)
        rightDataView.layer?.borderWidth = 1.0
        rightDataSubView = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(rightDataView.bounds.height) - 25, width: 200, height: 25))
        rightDataView.addSubview(rightDataSubView)
        
        
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
    }
    
    func orpheDidConnect(orphe:ORPData){
        PRINT("didConnect")
        tableView.reloadData()
        updateCellsState()
        
        orphe.setScene(.sceneSDK)
        orphe.setGestureSensitivity(.high)
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
        let sideInfo:Int32 = Int32(orphe.side.rawValue)
        var text = ""
        
        let quat = orphe.getQuat()
        for (i, q) in quat.enumerated() {
            text += "Quat\(i): "+String(q) + "\n"
        }
        
        let euler = orphe.getEuler()
        for (i, e) in euler.enumerated() {
            text += "Euler\(i): "+String(e) + "\n"
        }
        
        let acc = orphe.getAcc()
        for (i, a) in acc.enumerated() {
            text += "Acc\(i): "+String(a) + "\n"
        }
        
        let gyro = orphe.getGyro()
        for (i, g) in gyro.enumerated() {
            text +=  "Gyro\(i): "+String(g) + "\n"
        }
        
        let mag = orphe.getMag()
        text +=  "Mag: "+String(mag) + "\n"
        
        let shock = orphe.getShock()
        text += "Shock: "+String(shock) + "\n"
        
        if sideInfo == 0 {
            leftSensorLabel.stringValue = "LEFT\n\n" + text + "\n" + leftGesture
        }
        else{
            rightSensorLabel.stringValue = "RIGHT\n\n" + text + "\n" + rightGesture
        }
        
        //-----------Quat--------------
        for (i, q) in quat.enumerated() {
            //quatText += "\(i):" + String(q)
            if sideInfo == 0 {
                leftQuatSubView[i].textSubView.string = "\(i):" + String(q)
                leftQuatSubView[i].setGratphWidth(100, Int(q*100))
            }else{
                rightQuatSubView[i].textSubView.string = "\(i):" + String(q)
                rightQuatSubView[i].setGratphWidth(100, Int(q*100))
                
                //rightQuatText.string = quatText
                //rightQuatText[i].string = "\(i):" + String(q)
                //let textY = (rightQuatView.bounds.height - CGFloat(10*i))
                //rightQuatText[i].bounds.origin.y = textY
                //rightQuatSubView[i].frame = NSRect(x: Int(leftQuatView.bounds.width)/2, y: Int(leftQuatView.bounds.height)-10*i, width: Int(q*100), height: 10)
            }
        }
        //----------Euler----------
        for (i, e) in euler.enumerated() {
            //quatText += "\(i):" + String(q)
            if sideInfo == 0 {
                leftEulerSubView[i].textSubView.string = "\(i):" + String(e)
                leftEulerSubView[i].setGratphWidth(100, Int(e*100))
            }else{
                rightEulerSubView[i].textSubView.string = "\(i):" + String(e)
                rightEulerSubView[i].setGratphWidth(100, Int(e*100))
            }
        }
        //----------Acc----------
        
        //----------Gyro----------
        
        //----------Mag----------
        
        //----------Quat----------
        
        //----------Shock----------
        
        //----SelectedData----
        switch dataPopUp.title {
        case "Quat":
            let quatForGratph = quat.map{ $0 * 100 } //棒グラフ表示用に値を調整
            orpheDataDisplay(sideInfo: sideInfo, orpheDispData:quat, orpheDispDataForGratph: quatForGratph)
        case "Euler":
            let eulerForGratph = euler.map{ $0 * (100/180) }
            orpheDataDisplay(sideInfo: sideInfo, orpheDispData:euler, orpheDispDataForGratph: eulerForGratph)
        case "Acc":
            let accForGratph = acc.map{ $0 * 100 }
            orpheDataDisplay(sideInfo: sideInfo, orpheDispData:acc, orpheDispDataForGratph: accForGratph)
        case "Gyro":
            let gyroForGratph = gyro.map{ $0 * 100 }
            orpheDataDisplay(sideInfo: sideInfo, orpheDispData:gyro, orpheDispDataForGratph: gyroForGratph)
        case "Mag":
            let magArray:[Float] = [Float(mag)]
            let magForGratph:[Float] = [magArray[0]*(100/359)]
            orpheDataDisplay(sideInfo: sideInfo, orpheDispData:magArray, orpheDispDataForGratph: magForGratph)
        case "Shock":
            let shockArray:[Float] = [Float(shock)]
            let shockForGratph:[Float] = [shockArray[0]*(100/255)]
            orpheDataDisplay(sideInfo: sideInfo, orpheDispData:shockArray, orpheDispDataForGratph: shockForGratph)
        default:
            break
        }
    }
    
    func orpheDataDisplay(sideInfo:Int32,orpheDispData:[Float],orpheDispDataForGratph:[Float]){
        
        if sideInfo == 0 { //LEFT
            for i in 0..<orpheDispData.count{
                if i == dataParamPopUp.indexOfSelectedItem{
                    leftDataSubView.textSubView.string = "\(i):" + String(orpheDispData[i])
                    leftDataSubView.setGratphWidth(100, Int(orpheDispDataForGratph[i]))
                }
            }
        }else{ //RIGHT
            for i in 0..<orpheDispData.count{
                if i == dataParamPopUp.indexOfSelectedItem{
                    rightDataSubView.textSubView.string = "\(i):" + String(orpheDispData[i])
                    rightDataSubView.setGratphWidth(100, Int(orpheDispDataForGratph[i]))
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
