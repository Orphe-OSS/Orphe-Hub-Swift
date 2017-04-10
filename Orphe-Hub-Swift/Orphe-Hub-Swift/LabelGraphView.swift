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
    var graphSubView:DrawRectangle!
    var textSubView:NSTextView!
    
    
    override init(frame frameRect: NSRect){
        super.init(frame: frameRect)
        
        graphSubView = DrawRectangle(frame: NSRect(x: 100, y: 0, width: 0, height: 10))
        textSubView = NSTextView(frame: NSRect(x: 0, y: 10, width: 100, height: 10))
        textSubView.backgroundColor = NSColor.clear
        textSubView.string = ""
        textSubView.font = NSFont(name: textSubView.font!.fontName, size: 10)
        
        self.addSubview(graphSubView)
        self.addSubview(textSubView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setGratphWidth(_ x:Int,_ width:Int){
        var x_ = x
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
