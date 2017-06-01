//
//  MultiLineGraphView.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/05/31.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa

class MultiLineGraphView: NSView{
    
    var lineGraphArray = [LineGraphView]()
    
    init(frame frameRect: NSRect, lineNum:Int) {
        super.init(frame:frameRect);
        
        
        
    }
    
    override init(frame frameRect: NSRect){
        super.init(frame: frameRect)
        
        commonInit()
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
        
    }
    
    public required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    
    func commonInit(){
        self.layer?.backgroundColor = .black
    }
    
    func setLineNum(_ num:Int){
        let colors:[NSColor] = [.red, .green, .lightGray, .magenta, .yellow, .cyan]
        for i in 0..<num{
            let view = LineGraphView(frame: self.bounds)
            self.addSubview(view)
            
            var colorIndex = i
            while colorIndex > colors.count{
                colorIndex -= colors.count
            }
            view.lineColor = colors[colorIndex]
            lineGraphArray.append(view)
        }
    }
    
}
