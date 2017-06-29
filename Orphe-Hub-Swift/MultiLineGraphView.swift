//
//  MultiLineGraphView.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/05/31.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Cocoa

struct LineGraphLabel{
    var lineGraphView:LineGraphView
    var labelView:NSTextField
    var labelName:String
}

class MultiLineGraphView: NSView{
    
    var lineGraphLabelArray = [LineGraphLabel]()
    
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
        
    }
    
    func setAxis(_ axis:[String]){
        let colors:[NSColor] = [.red, .green, .lightGray, .magenta, .yellow, .cyan]
        
        //グラフ・ラベルのサイズ
        let labelWidth:CGFloat = 100
        let labelHeight:CGFloat = 15
        let graphRect = NSRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        
        for i in 0..<axis.count{
            
            //graphの生成
            let graphView = LineGraphView(frame: graphRect)
            self.addSubview(graphView)
            
            var colorIndex = i
            while colorIndex > colors.count{
                colorIndex -= colors.count
            }
            graphView.lineColor = colors[colorIndex]
            
            //最初のグラフのみ背景色つける
            if i == 0{
                graphView.layer?.backgroundColor = NSColor.darkGray.cgColor
            }
            
            //labelの生成
            let labelRect = NSRect(x: 0, y: graphRect.height-labelHeight*CGFloat(i+1), width: labelWidth, height: labelHeight)
            let label = NSTextField(frame: labelRect)
            label.drawsBackground = true;
            label.backgroundColor = NSColor.black.withAlphaComponent(0.4)
            label.isBordered = false;
            label.isEditable = false;
            label.isSelectable = false;
            label.stringValue = "-"
            label.textColor = colors[colorIndex]
            
            lineGraphLabelArray.append(LineGraphLabel(lineGraphView: graphView, labelView: label, labelName:axis[i]))
        }
        
        //labelをグラフ上に表示するために後でaddSubViewしてる
        for graphlabel in lineGraphLabelArray {
            self.addSubview(graphlabel.labelView)
        }
    }
    
    func updateDisplay(){
        for graphlabel in lineGraphLabelArray{
            graphlabel.lineGraphView.needsDisplay = true
        }
    }
    
    func updateLabel(values:[Float]){
        if values.count < lineGraphLabelArray.count{
            Swift.print("error: values count is lesser than lineGraphLabelArray count")
            return
        }
        for (i, view) in lineGraphLabelArray.enumerated(){
            let valStr = String(values[i])
            let text = view.labelName + ":" + valStr
            view.labelView.stringValue = text
        }
    }
}
