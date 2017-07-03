//
//  RecordPlaybackViewController.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/27.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa
import Orphe
import RxSwift
import RxCocoa

class RecordPlaybackViewController: ChildWindowViewController {
    
    @IBOutlet weak var startRecordButton: NSButton!
    
    @IBOutlet weak var playCSVButton: NSButton!
    @IBOutlet weak var stopCSVButton: NSButton!
    @IBOutlet weak var leftLoadCSVButton: NSButton!
    @IBOutlet weak var rightLoadCSVButton: NSButton!
    @IBOutlet weak var leftFileNameLabel: NSTextField!
    @IBOutlet weak var rightFileNameLabel: NSTextField!
    @IBOutlet weak var loopCheckButton: NSButton!
    
    var disposeBag = DisposeBag()
    
    //recorder
    var leftSensorRecorder = RecordSensorValuesCSV(side: .left)
    var rightSensorRecorder = RecordSensorValuesCSV(side: .right)
    
    //player
    var leftSensorPlayer = SensorValueCSVPlayer(side:.left)
    var rightSensorPlayer = SensorValueCSVPlayer(side:.right)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector:  #selector(ViewController.SensorValueCSVPlayerStopPlaying(notification:)), name: .SensorValueCSVPlayerStopPlaying, object: nil)
        
        startRecordButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            if self.startRecordButton.image == #imageLiteral(resourceName: "stopRecButton") {
                self.leftSensorRecorder.stopRecording()
                self.rightSensorRecorder.stopRecording()
                self.startRecordButton.image = #imageLiteral(resourceName: "startRecButton")
                
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
                self.startRecordButton.image = #imageLiteral(resourceName: "stopRecButton")
            }
        })
            .disposed(by: disposeBag)
        
        
        leftLoadCSVButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.loadCSV(side:.left)
            })
            .disposed(by: disposeBag)
        
        rightLoadCSVButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.loadCSV(side:.right)
            })
            .disposed(by: disposeBag)
        
        playCSVButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                if self.playCSVButton.image == #imageLiteral(resourceName: "startPlayButton"){
                    var isLeftSuccessPlay = false
                    var isRightSuccessPlay = false
                    if !ORPManager.sharedInstance.isLeftConnected(){
                        isLeftSuccessPlay = self.leftSensorPlayer.play()
                    }
                    if !ORPManager.sharedInstance.isRightConnected(){
                        isRightSuccessPlay = self.rightSensorPlayer.play()
                    }
                    if isLeftSuccessPlay || isRightSuccessPlay{
                        self.playCSVButton.image = #imageLiteral(resourceName: "pausePlayButton")
                    }
                }
                else{
                    self.leftSensorPlayer.pause()
                    self.rightSensorPlayer.pause()
                    self.playCSVButton.image = #imageLiteral(resourceName: "startPlayButton")
                }
            })
            .disposed(by: disposeBag)
        
        stopCSVButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                if self.playCSVButton.image == #imageLiteral(resourceName: "pausePlayButton"){
                    self.leftSensorPlayer.stop()
                    self.rightSensorPlayer.stop()
                    self.playCSVButton.image = #imageLiteral(resourceName: "startPlayButton")
                }
            })
            .disposed(by: disposeBag)
        
        loopCheckButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                if self.loopCheckButton.state == NSOnState{
                    self.leftSensorPlayer.isLoop = true
                    self.rightSensorPlayer.isLoop = true
                }
                else{
                    self.leftSensorPlayer.isLoop = false
                    self.rightSensorPlayer.isLoop = false
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        leftSensorPlayer.stop()
        rightSensorPlayer.stop()
        leftSensorRecorder.stopRecording()
        rightSensorRecorder.stopRecording()
    }
    
    func loadCSV(side:ORPSide){
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false // 複数ファイルの選択を許すか
        openPanel.canChooseDirectories = false // ディレクトリを選択できるか
        openPanel.canCreateDirectories = false // ディレクトリを作成できるか
        openPanel.canChooseFiles = true // ファイルを選択できるか
        openPanel.resolvesAliases = true
        openPanel.allowedFileTypes = ["csv"] // 選択できるファイル種別
        let result = openPanel.runModal() //Modalで開く。ファイル選ぶまで他の操作を出来ないように
        if result == NSFileHandlingPanelOKButton { // ファイルを選択したか(OKを押したか)
            guard let url = openPanel.url else { return }
            if side == .left{
                self.leftFileNameLabel.stringValue = url.lastPathComponent
                self.leftSensorPlayer.loadCSVFile(url: url)
            }
            else{
                self.rightFileNameLabel.stringValue = url.lastPathComponent
                self.rightSensorPlayer.loadCSVFile(url: url)
            }
        }
    }
    
    func SensorValueCSVPlayerStopPlaying(notification:Notification){
        guard let userInfo = notification.userInfo else {return}
        if !leftSensorPlayer.isPlaying && !rightSensorPlayer.isPlaying{
            self.playCSVButton.image = #imageLiteral(resourceName: "startPlayButton")
        }
    }
    
}
