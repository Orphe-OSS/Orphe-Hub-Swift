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
    
    let axisItems = ["x","y","z"]
    
    let axesItems = [
                    "x & y",
                    "y & z",
                    "z & x"
                    ]
    
    let resolutionFrequencyItems = [
                                "standard",
                                "2Byte/100Hz",
                                "2Byte/150Hz",
                                "1Byte/300Hz",
                                "2Byte/400Hz/1Axis",
                                "1Byte/400Hz/2Axes",
                                "2Byte/200Hz/2Axes",
                                "4Byte/200Hz/1Axis",
                                "4Byte/50Hz"
                                ]
    
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
            self.sendSetting()
            
        }).disposed(by: disposeBag)
        
        resolutionFrequencyPopUpButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            //update other popups
            self.updateAxisPopupItems()
            self.sendSetting()
            
        }).disposed(by: disposeBag)
        
        axisPopUpButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.sendSetting()
            
        }).disposed(by: disposeBag)
        
        setSensorSettingsButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.sendSetting()
        }).disposed(by: disposeBag)
        
        updateResolutionFrequencyPopupItems()
        updateAxisPopupItems()
    }
    
    func updateResolutionFrequencyPopupItems(){
        var resolutionFrequencyArray = [String]()
        
        switch self.sensorKindPopUpButton.titleOfSelectedItem!{
        case SensorKindItem.all.rawValue:
            resolutionFrequencyArray = [resolutionFrequencyItem.standard.rawValue]
            
        case SensorKindItem.acc.rawValue:
            for option in TransmissionOption.accOptions{
                resolutionFrequencyArray.append(resolutionFrequencyItems[option.hashValue])
            }
            
        case SensorKindItem.gyro.rawValue:
            for option in TransmissionOption.gyroOptions{
                resolutionFrequencyArray.append(resolutionFrequencyItems[option.hashValue])
            }
            
        case SensorKindItem.euler.rawValue:
            for option in TransmissionOption.eulerOptions{
                resolutionFrequencyArray.append(resolutionFrequencyItems[option.hashValue])
            }
            
        case SensorKindItem.quat.rawValue:
            for option in TransmissionOption.quatOptions{
                resolutionFrequencyArray.append(resolutionFrequencyItems[option.hashValue])
            }
            
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
            for axis in axisItems{
                axisArray.append(axis)
            }
            
        case resolutionFrequencyItem._2Byte200Hz2Axes.rawValue,
             resolutionFrequencyItem._1Byte400Hz2Axes.rawValue:
            for axes in axesItems{
                axisArray.append(axes)
            }
            
        default:
            break
        }
        
        self.axisPopUpButton.removeAllItems()
        self.axisPopUpButton.addItems(withTitles: axisArray)
    }
    
    func sendSetting(){
        var sendingType = TransmissionOption.standard
        switch resolutionFrequencyPopUpButton.titleOfSelectedItem! {
        case resolutionFrequencyItem.standard.rawValue:
            for orp in ORPManager.sharedInstance.connectedORPDataArray {
                orp.setSensorTransmissionStandard()
            }
            return
            
        case resolutionFrequencyItem._4Byte50Hz.rawValue:
            sendingType = TransmissionOption._50hz_4byte
            
        case resolutionFrequencyItem._2Byte100Hz.rawValue:
            sendingType = TransmissionOption._100hz_2byte
            
        case resolutionFrequencyItem._2Byte150Hz.rawValue:
            sendingType = TransmissionOption._150hz_2byte
            
        case resolutionFrequencyItem._2Byte200Hz2Axes.rawValue:
            sendingType = TransmissionOption._200hz_2byte_2axes
            
        case resolutionFrequencyItem._4Byte200Hz1Axis.rawValue:
            sendingType = TransmissionOption._200hz_4byte_1axis
            
        case resolutionFrequencyItem._1Byte300Hz.rawValue:
            sendingType = TransmissionOption._300hz_1byte
            
        case resolutionFrequencyItem._2Byte400Hz1Axis.rawValue:
            sendingType = TransmissionOption._400hz_2byte_1axis
            
        case resolutionFrequencyItem._1Byte400Hz2Axes.rawValue:
            sendingType = TransmissionOption._400hz_1byte_2axes
            
        default:
            break
        }
        
        var axisType = AxisOption.x_or_xy
        if self.axisPopUpButton.indexOfSelectedItem >= 0{
            axisType = AxisOption(rawValue:UInt8(self.axisPopUpButton.indexOfSelectedItem))!
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
        
        print( self.axisPopUpButton.indexOfSelectedItem )
        for orp in ORPManager.sharedInstance.connectedORPDataArray {
            orp.setSensorTransmissionOnly(measuredValue:sensorKind, transmissionOption:sendingType, axis:axisType)
        }
    }
    
}
