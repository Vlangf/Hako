//
//  NSColor+HexString.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa

extension NSColor {
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard hex.count == 6 || hex.count == 8 else { return nil }
        var rgbValue: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgbValue) else { return nil }

        if hex.count == 8 {
            self.init(
                red: CGFloat((rgbValue & 0xFF00_0000) >> 24) / 255.0,
                green: CGFloat((rgbValue & 0x00FF_0000) >> 16) / 255.0,
                blue: CGFloat((rgbValue & 0x0000_FF00) >> 8) / 255.0,
                alpha: CGFloat(rgbValue & 0x0000_00FF) / 255.0
            )
        } else {
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        }
    }
}
