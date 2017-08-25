//
//  OSCSettingViewController.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/27.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa
import Orphe
import OSCKit
import RxSwift
import RxCocoa

class OSCSettingViewController: ChildWindowViewController {
    @IBOutlet weak var oscHostTextField: NSTextField!
    @IBOutlet weak var oscSenderPortTextField: NSTextField!
    @IBOutlet weak var oscReceiverPortTextField: NSTextField!
    @IBOutlet var oscLogTextView: NSTextView!
    
    @IBOutlet weak var quatMapSettingView: MapValueSettingView!
    @IBOutlet weak var eulerMapSettingView: MapValueSettingView!
    @IBOutlet weak var accMapSettingView: MapValueSettingView!
    @IBOutlet weak var gyroMapSettingView: MapValueSettingView!
    @IBOutlet weak var magMapSettingView: MapValueSettingView!
    @IBOutlet weak var shockMapSettingView: MapValueSettingView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OSCManager.sharedInstance.delegate = self
        if !OSCManager.sharedInstance.isReceiving{
            if !OSCManager.sharedInstance.startReceive(){
                oscReceiverPortTextField.textColor = .red
            }
        }
        oscHostTextField.stringValue = OSCManager.sharedInstance.clientHost
        oscSenderPortTextField.stringValue = String(OSCManager.sharedInstance.clientPort)
        oscReceiverPortTextField.stringValue = String(OSCManager.sharedInstance.serverPort)
        oscLogTextView.font = NSFont(name: oscLogTextView.font!.fontName, size: 10)
        
        eulerMapSettingView.nameText.stringValue = mapSttingViewName.Angle.rawValue
        accMapSettingView.nameText.stringValue = mapSttingViewName.Accelerometer.rawValue
        gyroMapSettingView.nameText.stringValue = mapSttingViewName.Gyroscope.rawValue
        magMapSettingView.nameText.stringValue = mapSttingViewName.Magnetometer.rawValue
        shockMapSettingView.nameText.stringValue = mapSttingViewName.Shock.rawValue
        
        updateOSCLogTextView()
    }
    
    override func windowDidBecomeMain(_ notification: Notification) {
        super.windowDidBecomeMain(notification)
        
        quatMapSettingView.mapValue = OSCManager.sharedInstance.quatMapValue
        eulerMapSettingView.mapValue = OSCManager.sharedInstance.eulerMapValue
        accMapSettingView.mapValue = OSCManager.sharedInstance.accMapValue
        gyroMapSettingView.mapValue = OSCManager.sharedInstance.gyroMapValue
        magMapSettingView.mapValue = OSCManager.sharedInstance.magMapValue
        shockMapSettingView.mapValue = OSCManager.sharedInstance.shockMapValue
    }
    
    @IBAction func oscHostTextFieldInput(_ sender: NSTextField) {
        OSCManager.sharedInstance.clientHost = sender.stringValue
    }
    
    @IBAction func oscSenderPortTextFieldInput(_ sender: NSTextField) {
        if let input = Int(sender.stringValue){
            OSCManager.sharedInstance.clientPort = input
        }
        else{
            oscSenderPortTextField.stringValue = String(OSCManager.sharedInstance.clientPort)
        }
    }
    
    @IBAction func oscReceiverPortTextFieldInput(_ sender: NSTextField) {
        if let input = Int(sender.stringValue){
            OSCManager.sharedInstance.stopReceive()
            OSCManager.sharedInstance.serverPort = input
            
            if !OSCManager.sharedInstance.startReceive(){
                oscReceiverPortTextField.textColor = .red
            }
            else{
                oscReceiverPortTextField.textColor = .black
            }
        }
        else{
            oscReceiverPortTextField.stringValue = String(OSCManager.sharedInstance.serverPort)
        }
    }
    
}

//MARK: - OSCDelegate
extension OSCSettingViewController: OSCManagerDelegate{
    func oscDidReceiveMessage(message:String) {
        updateOSCLogTextView()
    }
    
    func updateOSCLogTextView(){
        var drawLines = ""
        for line in OSCManager.sharedInstance.oscReceivedMessages{
            drawLines += line+"\n"
        }
        oscLogTextView.string = drawLines
        oscLogTextView.scrollToEndOfDocument(oscLogTextView)
    }
}
