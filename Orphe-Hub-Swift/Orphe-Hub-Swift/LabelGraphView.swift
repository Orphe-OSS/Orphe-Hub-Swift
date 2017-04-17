//
//  LabelGraphView.swift
//  Orphe-Hub-Swift
//
//  Created by 平澤直之 on 2017/04/07.
//  Copyright © 2017年 no new folk studio Inc. All rights reserved.
//

import Cocoa

class LabelGraphView : NSView{
    
    //var labelGraphView = NSView()
    var graphBorderView:DrawRectangle!
    var graphSubView:DrawRectangle!
    var textSubView:NSTextView!
    
    var graphX = CGFloat(0)
    var graphHalfWidth = CGFloat(0)
    
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
        let x = self.frame.width/2
        graphX = x
        graphHalfWidth = self.frame.width/2
        let h = self.frame.height/2
        graphSubView = DrawRectangle(frame: NSRect(x: x, y: 0, width: 0, height: h))
        
        graphBorderView = DrawRectangle(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: h))
        graphBorderView.wantsLayer = true
        graphBorderView.layer?.borderWidth = 1.0
        graphBorderView.layer?.borderColor = CGColor(gray: 0.4, alpha: 1)
        graphBorderView.setColor(.clear)
        
        textSubView = NSTextView(frame: NSRect(x: 0, y: h, width: self.frame.width, height: h))
        textSubView.backgroundColor = NSColor.clear
        textSubView.string = "0"
        textSubView.font = NSFont(name: textSubView.font!.fontName, size: 10)
        
        self.addSubview(graphSubView)
        self.addSubview(graphBorderView)
        self.addSubview(textSubView)
    }
    
    func setGraphValue(_ value:CGFloat){
        var width = graphHalfWidth * value
        var x_ = graphX
        var w_ = width
        if (w_ < 0) {
            w_ = -w_
            x_ = x_ - w_
            graphSubView.setColor(NSColor.red)
        }else{
            graphSubView.setColor(NSColor.blue)
        }
        //graphSubView = DrawRectangle(frame: NSRect(x: x_, y: 0, width: w_, height: 10))
        graphSubView.frame = NSRect(x: x_, y: 0, width: w_, height: 10)
    }
    
    func setGraphWidth(_ width:CGFloat){
        var x_ = graphX
        var w_ = width
        if (w_ < 0) {
            w_ = -w_
            x_ = x_ - w_
            graphSubView.setColor(NSColor.red)
        }else{
            graphSubView.setColor(NSColor.blue)
        }
        //graphSubView = DrawRectangle(frame: NSRect(x: x_, y: 0, width: w_, height: 10))
        graphSubView.frame = NSRect(x: x_, y: 0, width: w_, height: 10)
    }
    
    
}
