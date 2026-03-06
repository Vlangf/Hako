//
//  HakoSplitView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/06/29.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa

class HakoSplitView: NSSplitView {

    // MARK: - Properties
    @IBInspectable var separatorColor: NSColor = .separatorColor {
        didSet {
            needsDisplay = true
        }
    }

    // MARK: - Draw
    override func drawDivider(in rect: NSRect) {
        separatorColor.setFill()
        rect.fill()
    }

}
