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
import RxSwift
import RxCocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var oscHostTextField: NSTextField!
    @IBOutlet weak var oscSenderTextField: NSTextField!
    @IBOutlet weak var oscReceiverTextField: NSTextField!
    @IBOutlet var oscLogTextView: NSTextView!
    
    var rssiTimer: Timer?
    
    @IBOutlet weak var leftSensorLabel: NSTextField!
    @IBOutlet weak var rightSensorLabel: NSTextField!
    @IBOutlet weak var leftGestureLabel: NSTextField!
    @IBOutlet weak var rightGestureLabel: NSTextField!
    
    @IBOutlet weak var sendingTypePopUpButton: NSPopUpButton!
    @IBOutlet weak var sensorKindPopUpButton: NSPopUpButton!
    @IBOutlet weak var axisPopUpButton: NSPopUpButton!
    
    @IBOutlet weak var accRangePopuUpButton: NSPopUpButton!
    @IBOutlet weak var gyroRangePopuUpButton: NSPopUpButton!
    
    
    @IBOutlet weak var leftLineGraph: NSView!
    @IBOutlet weak var rightLineGraph: NSView!
    var leftGraphArray = [LineGraphView]()
    var rightGraphArray = [LineGraphView]()
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.allowsTypeSelect = false
        
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
        oscLogTextView.font = NSFont(name: oscLogTextView.font!.fontName, size: 10)
        
        //sensor setting views
        let sendingTypeArray = ["Standard",
                                "2B_100H",
                                "2B_150H",
                                "1B_300H",
                                "1B_400H_2A",
                                "2B_400H_1A",
                                "2B_200H_2A",
                                "4B_200H_1A",
                                "4B_50H"]
        sendingTypePopUpButton.addItems(withTitles: sendingTypeArray)
        sendingTypePopUpButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.updateSendingSensorSetting()
        })
        .disposed(by: disposeBag)
        
        let sensorKindArray = ["Acc","Gyro","Euler","Quat"]
        sensorKindPopUpButton.addItems(withTitles: sensorKindArray)
        sensorKindPopUpButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.updateSendingSensorSetting()
        })
        .disposed(by: disposeBag)
        
        let axisTypeArray = ["x or xy", "y or yz","z or zx"]
        axisPopUpButton.addItems(withTitles: axisTypeArray)
        axisPopUpButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.updateSendingSensorSetting()
        })
        .disposed(by: disposeBag)
        
        let accRange = ["2g","4g","8g","16g"]
        accRangePopuUpButton.addItems(withTitles: accRange)
        accRangePopuUpButton.rx.tap.subscribe(onNext: { [weak self] _ in
            for orp in ORPManager.sharedInstance.connectedORPDataArray{
                orp.changeSensorRange(sensorKind: .acc, range: UInt8(self!.accRangePopuUpButton.indexOfSelectedItem))
            }
        })
        .disposed(by: disposeBag)
        
        let gyroRange = ["250°/sec","500°/sec","1000°/sec","2000°/sec"]
        gyroRangePopuUpButton.addItems(withTitles: gyroRange)
        gyroRangePopuUpButton.rx.tap.subscribe(onNext: { [weak self] _ in
            PRINT("gyro:",self!.gyroRangePopuUpButton.indexOfSelectedItem)
            for orp in ORPManager.sharedInstance.connectedORPDataArray{
                orp.changeSensorRange(sensorKind: .gyro, range: UInt8(self!.gyroRangePopuUpButton.indexOfSelectedItem))
            }
        })
        .disposed(by: disposeBag)
        
        //Notification
        NotificationCenter.default.addObserver(self, selector:  #selector(ViewController.OrpheDidUpdateSensorDataCustomised(notification:)), name: .OrpheDidUpdateSensorDataCustomised, object: nil)
        
    }
    
    override func viewDidLayout() {
        //graph
        setLineGraph(viewHolder: leftLineGraph, array: &leftGraphArray)
        setLineGraph(viewHolder: rightLineGraph, array: &rightGraphArray)
    }
    
    override var representedObject: Any? {
        didSet {
            
        }
    }
    
    func setLineGraph(viewHolder:NSView, array:inout Array<LineGraphView>){
        viewHolder.layer?.backgroundColor = .black
        let colors:[NSColor] = [.red, .green, .lightGray, .magenta, .yellow, .cyan]
        for i in 0..<colors.count{
            let view = LineGraphView(frame: viewHolder.bounds)
            viewHolder.addSubview(view)
            view.lineColor = colors[i]
            array.append(view)
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
    
    @IBAction func switchToOppositeSide(_ sender: Any) {
        for (index, _) in ORPManager.sharedInstance.availableORPDataArray.enumerated(){
            let orphe = ORPManager.sharedInstance.connectedORPDataArray[index]
            orphe.switchToOppositeSide()
        }
    }
    
    @IBAction func calibrationButtonAction(_ sender: Any) {
        for orphe in ORPManager.sharedInstance.connectedORPDataArray{
            orphe.calibrateAngle(axis: .X)
//            orphe.calibrateAngle(axis: .Y) //なんかおかしい
            orphe.calibrateAngle(axis: .Z)
        }
    }
    
    func updateSendingSensorSetting(){
        let sendingType = SendingType(rawValue: UInt8(self.sendingTypePopUpButton.indexOfSelectedItem + 40))!
        print("sendingType:", sendingType.rawValue)
        let sensorKind = SensorKind(rawValue: UInt8(self.sensorKindPopUpButton.indexOfSelectedItem))!
        let axisType = UInt8(self.axisPopUpButton.indexOfSelectedItem)
        for orp in ORPManager.sharedInstance.connectedORPDataArray {
            orp.changeSendingSensorState(sendingType: sendingType, sensorKind: sensorKind, axisType: axisType)
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
            if orp.state() != .connected{
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
            leftSensorLabel.stringValue = "LEFT Sensor\n\n" + text
        }
        else{
            rightSensorLabel.stringValue = "RIGHT Sensor\n\n" + text
        }
    }
    
    func drawSensorValuesOnLabel(orphe:ORPData, sensorKind:SensorKind){
        let sideInfo:Int32 = Int32(orphe.side.rawValue)
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
        for (j, array) in arrayArray.enumerated() {
            for (i, a) in array.enumerated() {
                text += sensorStr + "\(j)\(i): "+String(a) + "\n"
            }
        }
        
        if sideInfo == 0 {
            leftSensorLabel.stringValue = "LEFT Sensor\n\n" + text
            
            for array in arrayArray{
                for (index, val) in array.enumerated(){
                    leftGraphArray[index].addValue(CGFloat(val))
                }
            }
        }
        else{
            rightSensorLabel.stringValue = "RIGHT Sensor\n\n" + text
            
            for array in arrayArray{
                for (index, val) in array.enumerated(){
                    rightGraphArray[index].addValue(CGFloat(val))
                }
            }
        }
        
    }
    
    func OrpheDidUpdateSensorDataCustomised(notification: Notification){
        guard let userInfo = notification.userInfo else {return}
        let sendingType = userInfo[OrpheUpdatedSendingTypeInfoKey] as! SendingType
        let sensorKind = userInfo[OrpheUpdatedSenorKindInfoKey] as! SensorKind
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        
        drawSensorValuesOnLabel(orphe: orphe, sensorKind: sensorKind)
        
//        switch sendingType {
//        
//        case .t_2b_100h:
//            var arrayarray = [[Float]]()
//            if sensorKind == .acc{
//                arrayarray = orphe.getAccArray()
//            }
////            var str = ""
////            for array in arrayarray{
////                for val in array{
////                    str += ", "+String(val)
////                }
////            }
////            PRINT(str)
//            
//            
//        default:
//            break
//        }
        
    }
    
    func orpheDidCatchGestureEvent(gestureEvent:ORPGestureEventArgs, orphe:ORPData) {
        let side = orphe.side
        let kind = gestureEvent.getGestureKindString() as String
        let power = gestureEvent.getPower()
        let text = "Gesture: " + kind + "\n" + "power: " + String(power)
        
        if side == .left {
            leftGestureLabel.stringValue = "LEFT Gesture\n\n" + text
        }
        else{
            rightGestureLabel.stringValue = "RIGHT Gesture\n\n" + text
        }
    }
}

//MARK: - OSCDelegate
var lines = [String]()
extension ViewController: OSCManagerDelegate{
    func oscDidReceiveMessage(message:String) {
        lines.append(message)
        if lines.count > 30{
            lines.remove(at: 0)
        }
        
        var drawLines = ""
        for line in lines{
            drawLines = line + "\n" + drawLines
        }
        oscLogTextView.string = drawLines
    }
    
}
