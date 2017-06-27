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

class OSCSettingViewController: NSViewController {
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
        
        quatMapSettingView.mapValue = OSCManager.sharedInstance.quatMapValue
        
        eulerMapSettingView.mapValue = OSCManager.sharedInstance.eulerMapValue
        eulerMapSettingView.nameText.stringValue = "Angle"
        
        accMapSettingView.mapValue = OSCManager.sharedInstance.accMapValue
        accMapSettingView.nameText.stringValue = "Accelerometer"
        
        gyroMapSettingView.mapValue = OSCManager.sharedInstance.gyroMapValue
        gyroMapSettingView.nameText.stringValue = "Gyroscope"
        
        magMapSettingView.mapValue = OSCManager.sharedInstance.magMapValue
        magMapSettingView.nameText.stringValue = "Magnetometer"
        
        shockMapSettingView.mapValue = OSCManager.sharedInstance.shockMapValue
        shockMapSettingView.nameText.stringValue = "Shock"
        
        updateOSCLogTextView()
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
            oscReceiverPortTextField.textColor = .red
        }
        else{
            oscReceiverPortTextField.textColor = .black
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
            drawLines = drawLines + "\n" + line
        }
        oscLogTextView.string = drawLines
        oscLogTextView.scrollToEndOfDocument(oscLogTextView)
    }
}
