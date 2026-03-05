//
//  PreferencesWindowController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa
import SwiftUI

final class PreferencesWindowController: NSWindowController {

    static let shared: PreferencesWindowController = {
        let hostingController = NSHostingController(rootView: PreferencesView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = L10n.preferences
        window.styleMask = [.titled, .closable]
        window.collectionBehavior = .canJoinAllSpaces
        window.center()
        let controller = PreferencesWindowController(window: window)
        controller.windowFrameAutosaveName = "ClipyPreferences"
        return controller
    }()

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }
}
