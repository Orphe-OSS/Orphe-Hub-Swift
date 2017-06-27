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
    
    var oscLogLines = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OSCManager.sharedInstance.delegate = self
        if !OSCManager.sharedInstance.startReceive(){
            oscReceiverPortTextField.textColor = .red
        }
        oscHostTextField.stringValue = OSCManager.sharedInstance.clientHost
        oscSenderPortTextField.stringValue = String(OSCManager.sharedInstance.clientPort)
        oscReceiverPortTextField.stringValue = String(OSCManager.sharedInstance.serverPort)
        oscLogTextView.font = NSFont(name: oscLogTextView.font!.fontName, size: 10)
        
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
        oscLogLines.append(message)
        if oscLogLines.count > 30{
            oscLogLines.remove(at: 0)
        }
        
        var drawLines = ""
        for line in oscLogLines{
            drawLines = line + "\n" + drawLines
        }
        oscLogTextView.string = drawLines
    }
    
}
