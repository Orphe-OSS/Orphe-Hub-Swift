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
    
    @IBOutlet weak var activeLEDButton: NSButton!
    @IBOutlet weak var deactiveLEDButton: NSButton!
    
    var rssiTimer: Timer?
    
    @IBOutlet weak var sendingTypePopUpButton: NSPopUpButton!
    @IBOutlet weak var sensorKindPopUpButton: NSPopUpButton!
    @IBOutlet weak var axisPopUpButton: NSPopUpButton!
    
    @IBOutlet weak var accRangePopuUpButton: NSPopUpButton!
    @IBOutlet weak var gyroRangePopuUpButton: NSPopUpButton!
    
    @IBOutlet weak var startRecordButton: NSButton!
    
    @IBOutlet weak var rightSensorView: SensorVisualizerView!
    @IBOutlet weak var leftSensorView: SensorVisualizerView!
    
    var leftSensorRecorder = RecordSensorValuesCSV(side: .left)
    var rightSensorRecorder = RecordSensorValuesCSV(side: .right)
    
    var disposeBag = DisposeBag()
    
    
    var enableUpdateSensorValues = true
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.allowsTypeSelect = false
        
        leftSensorView.side = .left
        rightSensorView.side = .right
        
        ORPManager.sharedInstance.delegate = self
        ORPManager.sharedInstance.isEnableAutoReconnection = true
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
                                "2B_400H_1A",
                                "1B_400H_2A",
                                "2B_200H_2A",
                                "4B_200H_1A",
                                "4B_50H"]
        sendingTypePopUpButton.addItems(withTitles: sendingTypeArray)
        sendingTypePopUpButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.updateSendingSensorSetting()
            self?.leftSensorView.initFreqCalculators()
            self?.rightSensorView.initFreqCalculators()
        })
        .disposed(by: disposeBag)
        
        let sensorKindArray = ["Acc","Gyro","Euler","Quat"]
        sensorKindPopUpButton.addItems(withTitles: sensorKindArray)
        sensorKindPopUpButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.updateSendingSensorSetting()
            self?.leftSensorView.initFreqCalculators()
            self?.rightSensorView.initFreqCalculators()
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
                switch self!.accRangePopuUpButton.indexOfSelectedItem {
                case 0:
                    orp.setAccRange(range: ._2)
                case 1:
                    orp.setAccRange(range: ._4)
                case 2:
                    orp.setAccRange(range: ._8)
                case 3:
                    orp.setAccRange(range: ._16)

                default:
                    break
                }
            }
        })
        .disposed(by: disposeBag)
        
        let gyroRange = ["250°/sec","500°/sec","1000°/sec","2000°/sec"]
        gyroRangePopuUpButton.addItems(withTitles: gyroRange)
        gyroRangePopuUpButton.selectItem(at: 3)
        gyroRangePopuUpButton.rx.tap.subscribe(onNext: { [weak self] _ in
            PRINT("gyro:",self!.gyroRangePopuUpButton.indexOfSelectedItem)
            for orp in ORPManager.sharedInstance.connectedORPDataArray{
                switch self!.gyroRangePopuUpButton.indexOfSelectedItem {
                case 0:
                    orp.setGyroRange(range: ._250)
                case 1:
                    orp.setGyroRange(range: ._500)
                case 2:
                    orp.setGyroRange(range: ._1000)
                case 3:
                    orp.setGyroRange(range: ._2000)
                    
                default:
                    break
                }
            }
        })
        .disposed(by: disposeBag)
        
        startRecordButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            if self.startRecordButton.image == #imageLiteral(resourceName: "record-stop") {
                self.leftSensorRecorder.stopRecording()
                self.rightSensorRecorder.stopRecording()
                self.startRecordButton.image = #imageLiteral(resourceName: "record-start")
                
                //記録したデータの保存処理
                if self.leftSensorRecorder.recordText == ""
                    && self.rightSensorRecorder.recordText == ""{
                    return
                }
                
                let format = DateFormatter()
                format.dateFormat = "yyyy-MMdd-HHmmss"
                let filename = format.string(from: Date())
                let savePanel = NSSavePanel()
                savePanel.canCreateDirectories = true
                savePanel.showsTagField = false
                savePanel.nameFieldStringValue = filename
                savePanel.begin { (result) in
                    if result == NSFileHandlingPanelOKButton {
                        guard let url = savePanel.url else { return }
                        
                        var urlString = url.absoluteString
                        
                        //urlからfile://を削除する
                        let startIndex = urlString.startIndex
                        let endIndex = urlString.index(urlString.startIndex, offsetBy: 7)
                        urlString.removeSubrange(startIndex..<endIndex)
                        
                        if self.leftSensorRecorder.recordText != ""{
                            let leftUrlString = urlString+"-left.csv"
                            try! self.leftSensorRecorder.recordText.write(toFile: leftUrlString, atomically: true, encoding: String.Encoding.utf8)
                        }
                        
                        if self.rightSensorRecorder.recordText != ""{
                            let rightUrlString = urlString+"-right.csv"
                            try! self.rightSensorRecorder.recordText.write(toFile: rightUrlString, atomically: true, encoding: String.Encoding.utf8)
                        }
                    }
                }
            }
            else{
                self.leftSensorRecorder.startRecording()
                self.rightSensorRecorder.startRecording()
                self.startRecordButton.image = #imageLiteral(resourceName: "record-stop")
            }
        })
        .disposed(by: disposeBag)
        
        activeLEDButton.rx.tap.subscribe(onNext: { [weak self] _ in
            for orphe in ORPManager.sharedInstance.connectedORPDataArray{
                orphe.setLightState(isActive: true)
            }
        })
            .disposed(by: disposeBag)
        deactiveLEDButton.rx.tap.subscribe(onNext: { [weak self] _ in
            for orphe in ORPManager.sharedInstance.connectedORPDataArray{
                orphe.setLightState(isActive: false)
            }
        })
            .disposed(by: disposeBag)
        
        //Notification
        NotificationCenter.default.addObserver(self, selector:  #selector(ViewController.OrpheDidUpdateSensorData(notification:)), name: .OrpheDidUpdateSensorData, object: nil)
        
    }
    
    override func viewDidLayout() {
        //graph
        rightSensorView.initSettings()
        leftSensorView.initSettings()
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
        for (index, _) in ORPManager.sharedInstance.connectedORPDataArray.enumerated(){
            let orphe = ORPManager.sharedInstance.connectedORPDataArray[index]
            orphe.switchToOppositeSide()
        }
    }
    
    @IBAction func calibrationButtonAction(_ sender: Any) {
        for orphe in ORPManager.sharedInstance.connectedORPDataArray{
            orphe.calibrateAngle(axis: .X)
            orphe.calibrateAngle(axis: .Y) //なんかおかしい
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
    
    override func keyDown(with event: NSEvent) {
        if event.characters == " " {
            enableUpdateSensorValues = !enableUpdateSensorValues
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
        
//        orphe.setScene(.sceneSDK)
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
    
    
    func OrpheDidUpdateSensorData(notification: Notification){
        
        if !enableUpdateSensorValues {
            return
        }
        
        guard let userInfo = notification.userInfo else {return}
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        let sendingType = userInfo[OrpheUpdatedSendingTypeInfoKey] as! SendingType
        
        if orphe.side == .left {
            leftSensorView.updateSensorValues(orphe: orphe)
        }
        else{
            rightSensorView.updateSensorValues(orphe: orphe)
        }
    }
    
    func orpheDidCatchGestureEvent(gestureEvent:ORPGestureEventArgs, orphe:ORPData) {
        let side = orphe.side
        let kind = gestureEvent.getGestureKindString() as String
        let power = gestureEvent.getPower()
        let text = "Gesture: " + kind + "\n" + "power: " + String(power)
        
        if side == .left {
            leftSensorView.gestureLabel.stringValue = "LEFT Gesture\n\n" + text
        }
        else{
            rightSensorView.gestureLabel.stringValue = "RIGHT Gesture\n\n" + text
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
