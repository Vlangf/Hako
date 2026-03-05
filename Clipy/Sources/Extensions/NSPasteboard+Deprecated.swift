//
//  NSPasteboard+Deprecated.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2017/12/30.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa
import UniformTypeIdentifiers

extension NSPasteboard.PasteboardType {

    static var deprecatedString: NSPasteboard.PasteboardType {
        return .string
    }

    static var deprecatedRTF: NSPasteboard.PasteboardType {
        return .rtf
    }

    static var deprecatedRTFD: NSPasteboard.PasteboardType {
        return .rtfd
    }

    static var deprecatedPDF: NSPasteboard.PasteboardType {
        return .pdf
    }

    static var deprecatedFilenames: NSPasteboard.PasteboardType {
        return .fileURL
    }

    static var deprecatedURL: NSPasteboard.PasteboardType {
        return .URL
    }

    static var deprecatedTIFF: NSPasteboard.PasteboardType {
        return .tiff
    }

    // MARK: - Legacy rawValue mapping for NSCoding compatibility
    /// Maps old Swift 3-era rawValue strings stored in .data files to modern PasteboardType
    static func fromLegacyRawValue(_ rawValue: String) -> NSPasteboard.PasteboardType? {
        switch rawValue {
        case "NSStringPboardType":      return .string
        case "NSRTFPboardType":         return .rtf
        case "NSRTFDPboardType":        return .rtfd
        case "NSPDFPboardType":         return .pdf
        case "NSFilenamesPboardType":   return .fileURL
        case "NSURLPboardType":         return .URL
        case "NSTIFFPboardType":        return .tiff
        default:                        return NSPasteboard.PasteboardType(rawValue: rawValue)
        }
    }
}
