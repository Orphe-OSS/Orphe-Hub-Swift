//
//  mapValueSettingView.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/28.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class MapValueSettingView:NSView{
    
    @IBOutlet weak var nameText: NSTextField!
    @IBOutlet weak var minValueTextField: NSTextField!
    @IBOutlet weak var maxValueTextField: NSTextField!
    weak var mapValue:MapValue?{
        didSet{
            if mapValue != nil{
                minValueTextField.stringValue = String(describing: mapValue!.min)
                maxValueTextField.stringValue = String(describing: mapValue!.max)
            }
        }
    }
    
    var disposeBag = DisposeBag()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    // Storyboard/xib から初期化はここから
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    // xibからカスタムViewを読み込んで準備する
    fileprivate func commonInit() {
        // MyCustomView.xib からカスタムViewをロードする
        let bundle = Bundle(for: type(of: self))
        let className = NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
        let nib = NSNib(nibNamed: className, bundle: bundle)!
        var topLevelObjects = NSArray()
        nib.instantiate(withOwner: self, topLevelObjects: &topLevelObjects)
        let views = (topLevelObjects as Array).filter { $0 is NSView }
        let view = views.first as! NSView
        addSubview(view)
        
        // カスタムViewのサイズを自分自身と同じサイズにする
        view.translatesAutoresizingMaskIntoConstraints = false
        let bindings = ["view": view]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                      options:NSLayoutFormatOptions(rawValue: 0),
                                                      metrics:nil,
                                                      views: bindings))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                      options:NSLayoutFormatOptions(rawValue: 0),
                                                      metrics:nil,
                                                      views: bindings))
        
        
        minValueTextField.rx.controlEvent
            .subscribe(onNext: { [unowned self] _ in
                self.mapValue?.min = Float(self.minValueTextField.stringValue)!
            })
            .addDisposableTo(disposeBag)
        
        maxValueTextField.rx.controlEvent
            .subscribe(onNext: { [unowned self] _ in
                self.mapValue?.max = Float(self.maxValueTextField.stringValue)!
            })
            .addDisposableTo(disposeBag)
        
        
    }
    
}
