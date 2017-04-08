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

class ViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var leftSensorLabel: NSTextField!
    @IBOutlet weak var rightSensorLabel: NSTextField!
    
    @IBOutlet weak var oscHostTextField: NSTextField!
    @IBOutlet weak var oscSenderTextField: NSTextField!
    @IBOutlet weak var oscReceiverTextField: NSTextField!
    @IBOutlet var oscLogTextView: NSTextView!
    
    //hira
    @IBOutlet weak var leftView: NSView!
    @IBOutlet weak var rightView: NSView!
    //let r = NSRect(x:0, y:0, width:100, height:100)
    
    @IBOutlet weak var leftQuatView: NSView!
    @IBOutlet weak var rightQuatView: NSView!
    
    
    @IBAction func switchButton(_ sender: Any) {
        for (index, _) in ORPManager.sharedInstance.availableORPDataArray.enumerated(){
            let orphe = ORPManager.sharedInstance.connectedORPDataArray[index]
            orphe.switchToOppositeSide()
        }
    }
    
    //NSView
    var views = NSView()
    var views2 = NSView()
    var subview = Array<NSView>(repeating:NSView(), count:numData)
    var leftSubView = Array<NSView>(repeating:NSView(), count:numData)
    var rightSubView = Array<NSView>(repeating:NSView(), count:numData)
    
    var leftQuatSubView = Array<LabelGraphView>(repeating:LabelGraphView(), count:numQuat)
    //var leftQuatSubView = Array<LabelGraphView>(repeating:LabelGraphView(frame: NSRect(x: 0, y: 0, width: 100, height: 100)), count:numQuat)
    //var leftQuatSubView = Array<NSView>(repeating:NSView(), count:numQuat)
    //var leftQuatText = Array<NSTextView>(repeating:NSTextView(frame: NSRect(x: 0, y: 0, width: 100, height: 100)), count:numQuat)
    //var leftQuatText = NSTextView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
    
    var rightQuatSubView = Array<NSView>(repeating:NSView(), count:numQuat)
    //var rightQuatText = NSTextView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
    var rightQuatText = Array<NSTextView>(repeating:NSTextView(frame: NSRect(x: 0, y: 0, width: 100, height: 100)), count:numQuat)
    
    var leftText = NSTextField(frame: NSRect(x: 0, y: 1, width: 18, height: 23))
    
    var rssiTimer: Timer?
    
    var leftGesture = ""
    var rightGesture = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.allowsTypeSelect = false
        
        //subviewの初期化
        for i in 0..<numData {
            leftSubView[i] = DrawRectangle(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            leftView.addSubview(leftSubView[i])
            leftView.addSubview(leftText)
            rightSubView[i] = DrawRectangle(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            rightView.addSubview(rightSubView[i])
        }
        //----------Quat----------
        //leftQuatText.drawsBackground = true
        //leftQuatText.wantsLayer = true
        //leftQuatText.backgroundColor = NSColor.clear
        leftQuatView.layer?.borderWidth = 1.0
        for i in 0..<numQuat {
            //LEFT
            leftQuatSubView[i] = LabelGraphView(frame: NSRect(x: 0, y: 1+Int(leftQuatView.bounds.height) - 25*(i+1), width: 200, height: 25))
            leftQuatView.addSubview(leftQuatSubView[i])
            //RIGHT
            rightQuatText[i].backgroundColor = NSColor.clear
            rightQuatSubView[i] = DrawRectangle(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            rightQuatView.addSubview(rightQuatSubView[i])
            rightQuatView.addSubview(rightQuatText[i])
            //rightQuatText.frame = NSRect(x: 0, y: Int(rightQuatView.bounds.height), width: 100, height: 100)
        }
        
        
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
        let fontSize = Int((leftSensorLabel.font?.pointSize)!)+5
        var dateCount = 0
        
        let quat = orphe.getQuat()
        for (i, q) in quat.enumerated() {
            text += "Quat\(i): "+String(q) + "\n"
            //leftSubView[i].draw
            if sideInfo == 0 {
                leftSubView[i].frame = NSRect(x: Int(leftView.bounds.width)/2, y: Int(leftView.bounds.height) - (dateCount+i)*fontSize, width: Int(q*100), height: 10)
            }
            else{
                rightSubView[i].frame = NSRect(x: Int(leftView.bounds.width)/2, y: Int(rightView.bounds.height) - (dateCount+i)*fontSize, width: Int(q*100), height: 10)
            }
        }
        dateCount += quat.count
        
        let euler = orphe.getEuler()
        for (i, e) in euler.enumerated() {
            text += "Euler\(i):\(rightSensorLabel.frame.origin):\(leftSubView[dateCount+i].frame.origin): "+String(e) + "\n"
            if sideInfo == 0 {
                leftSubView[dateCount+i].frame = NSRect(x: Int(leftView.bounds.width)/2, y: Int(leftView.bounds.height) - (dateCount+i)*fontSize, width: Int(e), height: 10)
            }
            else{
                rightSubView[dateCount+i].frame = NSRect(x: Int(leftView.bounds.width)/2, y: Int(rightView.bounds.height) - (dateCount+i)*fontSize, width: Int(e), height: 10)
            }
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
            leftText.stringValue = "LEFT\n\n" + text + "\n" + leftGesture
        }
        else{
            rightSensorLabel.stringValue = "RIGHT\n\n" + text + "\n" + rightGesture
        }
        
        //-----------hira
        //var quatText = "Quat\n"
        //leftQuatText.frame = NSRect(x: 0, y: Int(leftQuatView.bounds.height), width: 100, height: 100)
        
        for (i, q) in quat.enumerated() {
            //quatText += "\(i):" + String(q)
            if sideInfo == 0 {
                //leftQuatSubView[i].frame = NSRect(x: Int(leftQuatView.bounds.width)/2, y: Int(leftQuatView.bounds.height)-10*i, width: 100, height: 100)
                leftQuatSubView[i].textSubView.string = "\(i):" + String(q)
                //leftQuatSubView[i].graphSubView.frame = NSRect(x: 50, y: 0, width: Int(q*100), height: 10)
                leftQuatSubView[i].setGratphWidth(100, Int(q*100))
            }else{
                //rightQuatText.string = quatText
                rightQuatText[i].string = "\(i):" + String(q)
                let textY = (rightQuatView.bounds.height - CGFloat(10*i))
                rightQuatText[i].bounds.origin.y = textY
                rightQuatSubView[i].frame = NSRect(x: Int(leftQuatView.bounds.width)/2, y: Int(leftQuatView.bounds.height)-10*i, width: Int(q*100), height: 10)
                
                //左の残骸
//                leftQuatText[i].string = "\(i):" + String(q)
//                let textY = leftQuatView.bounds.height - CGFloat(10*i)
//                leftQuatText[i].bounds.origin.y = textY
//                leftQuatSubView[i].frame = NSRect(x: Int(leftQuatView.bounds.width)/2, y: Int(leftQuatView.bounds.height)-10*i, width: Int(q*100), height: 10)
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
