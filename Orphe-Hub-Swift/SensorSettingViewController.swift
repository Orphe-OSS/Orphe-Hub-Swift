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
    
    @IBOutlet weak var accRangeSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var gyroRangeSegmentedControl: NSSegmentedControl!
    
    @IBOutlet weak var sensorKindPopUpButton: NSPopUpButton!
    @IBOutlet weak var resolutionFrequencyPopUpButton: NSPopUpButton!
    @IBOutlet weak var axisPopUpButton: NSPopUpButton!
    
    @IBOutlet weak var setSensorSettingsButton: NSButton!
    
    var disposeBag = DisposeBag()
    
    enum SensorKindItem:String{
        case all
        case acc
        case gyro
        case euler
        case quat
    }
    
    enum resolutionFrequencyItem:String{
        case standard
        case _2Byte100Hz = "2Byte/100Hz"
        case _2Byte150Hz = "2Byte/150Hz"
        case _1Byte300Hz = "1Byte/300Hz"
        case _2Byte400Hz1Axis = "2Byte/400Hz/1Axis"
        case _1Byte400Hz2Axes = "1Byte/400Hz/2Axes"
        case _2Byte200Hz2Axes = "2Byte/200Hz/2Axes"
        case _4Byte200Hz1Axis = "4Byte/200Hz/1Axis"
        case _4Byte50Hz = "4Byte/50Hz"
    }
    
    enum axisItem:String{
        case x
        case y
        case z
    }
    
    enum axesItem:String{
        case xy = "x & y"
        case yz = "y & z"
        case zx = "z & x"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //レンジ設定UI
        accRangeSegmentedControl.rx.controlEvent.subscribe(onNext: { [unowned self] _ in
            for orp in ORPManager.sharedInstance.connectedORPDataArray{
                switch self.accRangeSegmentedControl.selectedSegment {
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
        
        
        gyroRangeSegmentedControl.rx.controlEvent.subscribe(onNext: { [unowned self] _ in
            for orp in ORPManager.sharedInstance.connectedORPDataArray{
                switch self.gyroRangeSegmentedControl.selectedSegment {
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
        
        
        //センサ送信設定UI
        var sensorKindArray = [String]()
        for item in iterateEnum(SensorKindItem.self){
            sensorKindArray.append(item.rawValue)
        }
        sensorKindPopUpButton.addItems(withTitles: sensorKindArray)
        sensorKindPopUpButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            //update other popups
            self.updateResolutionFrequencyPopupItems()
            self.updateAxisPopupItems()
            self.updateSendingSensorSetting()
            
        })
         .disposed(by: disposeBag)
        
        resolutionFrequencyPopUpButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            //update other popups
            self.updateAxisPopupItems()
            self.updateSendingSensorSetting()
            
        })
            .disposed(by: disposeBag)
        
        
        setSensorSettingsButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.updateSendingSensorSetting()
            self.updateSendingSensorSetting()
        })
            .disposed(by: disposeBag)
        
        updateResolutionFrequencyPopupItems()
        updateAxisPopupItems()
    }
    
    func updateResolutionFrequencyPopupItems(){
        var resolutionFrequencyArray = [String]()
        
        switch self.sensorKindPopUpButton.titleOfSelectedItem!{
        case SensorKindItem.all.rawValue:
            resolutionFrequencyArray = [resolutionFrequencyItem.standard.rawValue]
            
        case SensorKindItem.acc.rawValue:
            resolutionFrequencyArray = [
                resolutionFrequencyItem._2Byte100Hz.rawValue,
                resolutionFrequencyItem._2Byte150Hz.rawValue,
                resolutionFrequencyItem._1Byte300Hz.rawValue,
                resolutionFrequencyItem._2Byte400Hz1Axis.rawValue,
                resolutionFrequencyItem._1Byte400Hz2Axes.rawValue,
                resolutionFrequencyItem._2Byte200Hz2Axes.rawValue,
            ]
            
        case SensorKindItem.gyro.rawValue:
            resolutionFrequencyArray = [
                resolutionFrequencyItem._2Byte100Hz.rawValue,
                resolutionFrequencyItem._2Byte150Hz.rawValue,
                resolutionFrequencyItem._1Byte300Hz.rawValue,
                resolutionFrequencyItem._2Byte400Hz1Axis.rawValue,
                resolutionFrequencyItem._1Byte400Hz2Axes.rawValue,
                resolutionFrequencyItem._2Byte200Hz2Axes.rawValue,
            ]
            
        case SensorKindItem.euler.rawValue:
            resolutionFrequencyArray = [
                resolutionFrequencyItem._2Byte100Hz.rawValue,
                resolutionFrequencyItem._2Byte150Hz.rawValue,
                resolutionFrequencyItem._2Byte200Hz2Axes.rawValue,
                resolutionFrequencyItem._4Byte200Hz1Axis.rawValue,
                resolutionFrequencyItem._4Byte50Hz.rawValue,
            ]
            
        case SensorKindItem.quat.rawValue:
            resolutionFrequencyArray = [
                resolutionFrequencyItem._2Byte100Hz.rawValue,
                resolutionFrequencyItem._4Byte50Hz.rawValue,
            ]
            
        default:
            break
        }
        self.resolutionFrequencyPopUpButton.removeAllItems()
        self.resolutionFrequencyPopUpButton.addItems(withTitles: resolutionFrequencyArray)
        self.resolutionFrequencyPopUpButton.selectItem(at: 0)
    }
    
    func updateAxisPopupItems(){
        var axisArray = [String]()
        
        switch self.resolutionFrequencyPopUpButton.titleOfSelectedItem!{
        case resolutionFrequencyItem.standard.rawValue,
             resolutionFrequencyItem._1Byte300Hz.rawValue,
             resolutionFrequencyItem._2Byte100Hz.rawValue,
             resolutionFrequencyItem._4Byte50Hz.rawValue,
             resolutionFrequencyItem._2Byte150Hz.rawValue:
            axisArray.append("-")
            
        case resolutionFrequencyItem._2Byte400Hz1Axis.rawValue,
             resolutionFrequencyItem._4Byte200Hz1Axis.rawValue:
            for item in iterateEnum(axisItem.self){
                axisArray.append(item.rawValue)
            }
            
        case resolutionFrequencyItem._2Byte200Hz2Axes.rawValue,
             resolutionFrequencyItem._1Byte400Hz2Axes.rawValue:
            for item in iterateEnum(axesItem.self){
                axisArray.append(item.rawValue)
            }
            
        default:
            break
        }
        
        self.axisPopUpButton.removeAllItems()
        self.axisPopUpButton.addItems(withTitles: axisArray)
    }
    
    func updateSendingSensorSetting(){
        var sendingType = SendingType(rawValue: UInt8(self.resolutionFrequencyPopUpButton.indexOfSelectedItem + 40))!
        switch resolutionFrequencyPopUpButton.titleOfSelectedItem! {
        case resolutionFrequencyItem.standard.rawValue:
            sendingType = SendingType.standard
            
        case resolutionFrequencyItem._4Byte50Hz.rawValue:
            sendingType = SendingType.standard
            
        case resolutionFrequencyItem._2Byte100Hz.rawValue:
            sendingType = SendingType.t_2b_100h
            
        case resolutionFrequencyItem._2Byte150Hz.rawValue:
            sendingType = SendingType.t_2b_150h
            
        case resolutionFrequencyItem._2Byte200Hz2Axes.rawValue:
            sendingType = SendingType.t_2b_200h_2a
            
        case resolutionFrequencyItem._4Byte200Hz1Axis.rawValue:
            sendingType = SendingType.t_4b_200h_1a
            
        case resolutionFrequencyItem._1Byte300Hz.rawValue:
            sendingType = SendingType.t_1b_300h
            
        case resolutionFrequencyItem._2Byte400Hz1Axis.rawValue:
            sendingType = SendingType.t_2b_400h_1a
            
        case resolutionFrequencyItem._1Byte400Hz2Axes.rawValue:
            sendingType = SendingType.t_1b_400h_2a
            
        default:
            break
        }
        
        var sensorKind = SensorKind(rawValue: UInt8(self.sensorKindPopUpButton.indexOfSelectedItem))!
        switch sensorKindPopUpButton.titleOfSelectedItem! {
        case SensorKindItem.all.rawValue:
            break
            
        case SensorKindItem.acc.rawValue:
            sensorKind = .acc
            
        case SensorKindItem.gyro.rawValue:
            sensorKind = .gyro
            
        case SensorKindItem.euler.rawValue:
            sensorKind = .euler
            
        case SensorKindItem.quat.rawValue:
            sensorKind = .quat
            
        default:
            break
        }
        
        var axisType = UInt8(0)
        if self.axisPopUpButton.indexOfSelectedItem >= 0{
            axisType = UInt8(self.axisPopUpButton.indexOfSelectedItem)
        }
        print( self.axisPopUpButton.indexOfSelectedItem )
        for orp in ORPManager.sharedInstance.connectedORPDataArray {
            orp.changeSendingSensorState(sendingType: sendingType, sensorKind: sensorKind, axisType: axisType)
        }
    }
    
}
