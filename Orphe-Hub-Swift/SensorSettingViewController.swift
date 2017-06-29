//
//  SensorSettingViewController.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/27.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa
import Orphe
import RxSwift
import RxCocoa

class SensorSettingViewController: ChildWindowViewController {
    
    @IBOutlet weak var sendingTypePopUpButton: NSPopUpButton!
    @IBOutlet weak var sensorKindPopUpButton: NSPopUpButton!
    @IBOutlet weak var axisPopUpButton: NSPopUpButton!
    
    @IBOutlet weak var accRangePopuUpButton: NSPopUpButton!
    @IBOutlet weak var gyroRangePopuUpButton: NSPopUpButton!
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
