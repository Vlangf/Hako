//
//  MoveToApplications.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa

enum MoveToApplications {
    static func moveIfNecessary() {
        let bundlePath = Bundle.main.bundlePath
        let applicationsDir = "/Applications"
        guard !bundlePath.hasPrefix(applicationsDir) else { return }

        let alert = NSAlert()
        alert.messageText = "Move to Applications folder?"
        alert.informativeText = "Hako needs to be in your Applications folder to work properly. Would you like to move it there now?"
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Do Not Move")
        NSApp.activate(ignoringOtherApps: true)

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let appName = (bundlePath as NSString).lastPathComponent
        let destinationPath = (applicationsDir as NSString).appendingPathComponent(appName)
        let fileManager = FileManager.default

        do {
            if fileManager.fileExists(atPath: destinationPath) {
                try fileManager.removeItem(atPath: destinationPath)
            }
            try fileManager.moveItem(atPath: bundlePath, toPath: destinationPath)
            // Relaunch from new location
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [destinationPath]
            task.launch()
            NSApp.terminate(nil)
        } catch {
            let errorAlert = NSAlert()
            errorAlert.messageText = "Could not move to Applications folder"
            errorAlert.informativeText = error.localizedDescription
            errorAlert.runModal()
        }
    }
}
