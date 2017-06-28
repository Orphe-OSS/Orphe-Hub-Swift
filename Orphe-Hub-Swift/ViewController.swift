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
    
    @IBOutlet weak var activeLEDButton: NSButton!
    @IBOutlet weak var deactiveLEDButton: NSButton!
    
    var rssiTimer: Timer?
    
    @IBOutlet weak var rightSensorView: SensorVisualizerView!
    @IBOutlet weak var leftSensorView: SensorVisualizerView!
    
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
        NotificationCenter.default.addObserver(self, selector:  #selector(ViewController.OrpheDidReceiveFWVersion(notification:)), name: .OrpheDidReceiveFWVersion, object: nil)
        
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
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
            
            //接続状態で行の背景色を変える
            if let row = tableView.rowView(atRow: index, makeIfNecessary: true){
                if orp.state() == .connected{
                    row.backgroundColor = NSColor.darkGray
                }
                else{
                    row.backgroundColor = NSColor.white
                }
            }
            
            //接続状態で文字の色を変える
            for (columnNum, _) in tableView.tableColumns.enumerated(){
                if let cell = tableView.view(atColumn: columnNum, row: index, makeIfNecessary: true) as? NSTableCellView{
                    if orp.state() == .connected{
                        cell.textField?.textColor = NSColor.yellow
                    }
                    else{
                        cell.textField?.textColor = NSColor.black
                    }
                    
                    if let cell = tableView.view(atColumn: 2, row: index, makeIfNecessary: true) as? NSTableCellView{
                        var sideStr = "LEFT"
                        if orp.side == .right {
                            sideStr = "RIGHT"
                        }
                        cell.textField?.stringValue = sideStr
                    }
                    if let cell = tableView.view(atColumn: 3, row: index, makeIfNecessary: true) as? NSTableCellView{
                        cell.textField?.stringValue = String(orp.fwVersion)
                    }
                }
            }
            
        }
    }
    
    @IBAction func switchToOppositeSide(_ sender: Any) {
        for (index, _) in ORPManager.sharedInstance.connectedORPDataArray.enumerated(){
            let orphe = ORPManager.sharedInstance.connectedORPDataArray[index]
            orphe.switchToOppositeSide()
        }
        updateCellsState()
    }
    
    @IBAction func calibrationButtonAction(_ sender: Any) {
        for orphe in ORPManager.sharedInstance.connectedORPDataArray{
            orphe.calibrateAngle(axis: .X)
            orphe.calibrateAngle(axis: .Y) //なんかおかしい
            orphe.calibrateAngle(axis: .Z)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == " " {
            enableUpdateSensorValues = !enableUpdateSensorValues
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "toOSCSettingVC":
            for window in NSApplication.shared().windows{
                if window.contentViewController is OSCSettingViewController{
                    window.orderFrontRegardless()
                    return false
                }
            }
        case "toRecordPlaybackVC":
            for window in NSApplication.shared().windows{
                if window.contentViewController is RecordPlaybackViewController{
                    window.orderFrontRegardless()
                    return false
                }
            }
        case "toSensorSettingVC":
            for window in NSApplication.shared().windows{
                if window.contentViewController is SensorSettingViewController{
                    window.orderFrontRegardless()
                    return false
                }
            }
        default:
            break
        }
        
        return true
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let wc = segue.destinationController as? NSWindowController else {return}
        //常に子windowを親windowの上に表示するための処理
        if let childWindow = wc.window{
            let parentWindow : NSWindow = self.view.window!
            parentWindow.orderFront(self)
            parentWindow.makeKeyAndOrderFront(self)
            
            childWindow.orderFront(self)
            childWindow.makeKeyAndOrderFront(self)
            parentWindow.addChildWindow(childWindow, ordered: NSWindowOrderingMode.above)
        }
    }
    
}

//MARK: - NSTableViewDelegate
extension  ViewController: NSTableViewDelegate{
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let cellIdentifier: String = "NameCell"
        
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.drawsBackground = true
            if tableColumn == tableView.tableColumns[0] {
                cell.textField?.stringValue = ORPManager.sharedInstance.availableORPDataArray[row].name
            }
            else if tableColumn == tableView.tableColumns[1] {
                cell.textField?.stringValue = "0"
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
        if orphe.side == .left{
            leftSensorView.stopUpdateGraphView()
        }
        else{
            rightSensorView.stopUpdateGraphView()
        }
    }
    
    func orpheDidConnect(orphe:ORPData){
        
        PRINT("didConnect")
        tableView.reloadData()
        
        updateCellsState()
        
//        orphe.setScene(.sceneSDK)
        orphe.setGestureSensitivity(.high)
        
        if orphe.side == .left{
            leftSensorView.startUpdateGraphView()
        }
        else{
            rightSensorView.startUpdateGraphView()
        }
        
    }

    func OrpheDidReceiveFWVersion(notification: Notification){
        guard let userInfo = notification.userInfo else {return}
        let orphe = userInfo[OrpheDataUserInfoKey] as! ORPData
        
        updateCellsState()
    }
    
    func orpheDidUpdateOrpheInfo(orphe:ORPData){
        PRINT("didUpdateOrpheInfo")
        updateCellsState()
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
