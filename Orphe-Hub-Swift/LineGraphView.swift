//
//  LineGraphView.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/05/12.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa

class LineGraphView: NSView{
    var dataArray = [CGFloat]()
    var xInterval:CGFloat = 1.0
    var yInterval:CGFloat = 1.0
    var valueMax:CGFloat = 1.1
    var valueMin:CGFloat = -1.1
    var bufSize:Int = 256
    var lineColor:NSColor = .red
    
    
    var updateTimer:Timer!
    
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
        dataArray = Array(repeating: 0, count: bufSize)
        xInterval = CGFloat(self.frame.width) / CGFloat(dataArray.count)
        yInterval = CGFloat(self.frame.height) / (valueMax-valueMin)
    }
    
    func addValue(_ value:CGFloat){
        dataArray.removeFirst()
        dataArray.append(value)
    }
    
    func updateView(tm: Timer){
        self.needsDisplay = true
    }
    
    func startUpdateView(){
        updateTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.updateView), userInfo: nil, repeats: true)
    }
    
    func stopUpdateView(){
        updateTimer.invalidate()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let centerLine = NSBezierPath()
        centerLine.move(to: CGPoint(x: 0, y: CGFloat(self.frame.height) / 2))
        centerLine.line(to: NSPoint(x: self.frame.width, y:CGFloat(self.frame.height) / 2))
        NSColor.white.setStroke()
        centerLine.lineWidth = 1
        centerLine.stroke()
        
        let line = NSBezierPath()
        // 起点
        line.move(to: CGPoint(x: 0, y: CGFloat(self.frame.height) / 2))
        for (index, data) in dataArray.enumerated() {
            line.line(to: NSPoint(x: CGFloat(index) * xInterval, y: data*yInterval + CGFloat(self.frame.height) / 2))
        }
        
        // 色の設定
        lineColor.setStroke()
        // ライン幅
        line.lineWidth = 2
        // 描画
        line.stroke()
        
    }
}
