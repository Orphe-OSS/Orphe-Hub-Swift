//
//  DrawShape.swift
//  Orphe-Hub-Swift
//
//  Created by 平澤直之 on 2017/04/05.
//  Copyright © 2017年 no new folk studio Inc. All rights reserved.
//

import Foundation

import Cocoa
import Orphe
import OSCKit

class DrawCircle: NSView{
    override func draw(_ dirtyRect: NSRect) {
        
        let context = NSGraphicsContext.current?.cgContext
        NSColor.blue.set()
        context?.addEllipse(in: dirtyRect)
        context?.fillPath()
        
    }
}

class DrawRectangle: NSView{
    var bColor:NSColor = NSColor.blue

    override func draw(_ dirtyRect: NSRect) {
        let context = NSGraphicsContext.current?.cgContext
        bColor.set()
        context?.addRect(bounds)
        context?.fillPath()
    }

    func setColor(_ color:NSColor){
        bColor = color
        needsDisplay = true
    }
}

class BorderRectangle: NSView{
    var borderColor:NSColor = NSColor.gray
    var borderWidth:CGFloat = 1.0

    override func draw(_ dirtyRect: NSRect) {
        let context = NSGraphicsContext.current?.cgContext
        // Clear background
        NSColor.clear.set()
        context?.fill(bounds)
        // Draw border
        borderColor.set()
        let borderRect = bounds.insetBy(dx: borderWidth/2, dy: borderWidth/2)
        context?.setLineWidth(borderWidth)
        context?.stroke(borderRect)
    }
}
