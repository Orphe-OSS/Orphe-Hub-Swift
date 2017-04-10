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

class ViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var oscHostTextField: NSTextField!
    @IBOutlet weak var oscSenderTextField: NSTextField!
    @IBOutlet weak var oscReceiverTextField: NSTextField!
    @IBOutlet var oscLogTextView: NSTextView!
    
    @IBOutlet weak var rightMIDIMappingViewHolder:NSView!
    @IBOutlet weak var leftMIDIMappingViewHolder:NSView!
    var rightMIDIMappingView:MIDIMappingView!
    var leftMIDIMappingView:MIDIMappingView!
    
    var rssiTimer: Timer?
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        rightMIDIMappingView = MIDIMappingView.newMIDIMappingView()
        rightMIDIMappingViewHolder.addSubview(rightMIDIMappingView)
        
        leftMIDIMappingView = MIDIMappingView.newMIDIMappingView()
        leftMIDIMappingViewHolder.addSubview(leftMIDIMappingView)
        
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
        
        //MIDI
        MIDIManager.sharedInstance.initMIDI()
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
        var tempOrphe =
            leftMIDIMappingView.orphe
        leftMIDIMappingView.orphe = rightMIDIMappingView.orphe
        rightMIDIMappingView.orphe = tempOrphe
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
        orphe.switchLight(lightNum: 5, flag: true)
        orphe.setGestureSensitivity(.high)
        
        if orphe.side == .left{
            leftMIDIMappingView.orphe = orphe
        }
        else{
            rightMIDIMappingView.orphe = orphe
        }
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
        
        leftMIDIMappingView.orpheDidUpdateSensorData(orphe: orphe)
        rightMIDIMappingView.orpheDidUpdateSensorData(orphe: orphe)
        
    }
    
    func orpheDidCatchGestureEvent(gestureEvent:ORPGestureEventArgs, orphe:ORPData) {
//        let side = orphe.side
//        let kind = gestureEvent.getGestureKindString() as String
//        let power = gestureEvent.getPower()
    }
}

extension ViewController: OSCManagerDelegate{
    func oscDidReceiveMessage(message:String) {
        oscLogTextView.string = message + "\n" + oscLogTextView.string!
    }
}
