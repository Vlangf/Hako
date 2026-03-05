//
//  AppDelegate.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2015/06/21.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa
import Sparkle
import Combine
import ServiceManagement
import Magnet
import SwiftData

@NSApplicationMain
class AppDelegate: NSObject {

    // MARK: - Properties
    let screenshotObserver = ScreenshotObserver()
    var cancellables = Set<AnyCancellable>()
    let updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)

    // MARK: - Override Methods
    @MainActor
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(AppDelegate.clearAllHistory) {
            return PersistenceController.shared.clipCount() > 0
        }
        return true
    }

    // MARK: - Class Methods
    static func storeTypesDictinary() -> [String: NSNumber] {
        var storeTypes = [String: NSNumber]()
        CPYClipData.availableTypesString.forEach { storeTypes[$0] = NSNumber(value: true) }
        return storeTypes
    }

    // MARK: - Menu Actions
    @objc func showPreferenceWindow() {
        NSApp.activate(ignoringOtherApps: true)
        PreferencesWindowController.shared.showWindow(self)
    }

    @objc func showSnippetEditorWindow() {
        NSApp.activate(ignoringOtherApps: true)
        CPYSnippetsEditorWindowController.sharedController.showWindow(self)
    }

    @objc func terminate() {
        terminateApplication()
    }

    @MainActor @objc func clearAllHistory() {
        let isShowAlert = AppState.shared.defaults.bool(forKey: Constants.UserDefaults.showAlertBeforeClearHistory)
        if isShowAlert {
            let alert = NSAlert()
            alert.messageText = L10n.clearHistory
            alert.informativeText = L10n.areYouSureYouWantToClearYourClipboardHistory
            alert.addButton(withTitle: L10n.clearHistory)
            alert.addButton(withTitle: L10n.cancel)
            alert.showsSuppressionButton = true

            NSApp.activate(ignoringOtherApps: true)

            let result = alert.runModal()
            if result != NSApplication.ModalResponse.alertFirstButtonReturn { return }

            if alert.suppressionButton?.state == NSControl.StateValue.on {
                AppState.shared.defaults.set(false, forKey: Constants.UserDefaults.showAlertBeforeClearHistory)
            }
            AppState.shared.defaults.synchronize()
        }

        AppState.shared.clipService.clearAll()
    }

    @MainActor
    @objc func selectClipMenuItem(_ sender: NSMenuItem) {
        CPYUtilities.sendCustomLog(with: "selectClipMenuItem")
        guard let primaryKey = sender.representedObject as? String else {
            CPYUtilities.sendCustomLog(with: "Cannot fetch clip primary key")
            NSSound.beep()
            return
        }
        guard let clip = PersistenceController.shared.fetchClip(byHash: primaryKey) else {
            CPYUtilities.sendCustomLog(with: "Cannot fetch clip data")
            NSSound.beep()
            return
        }

        AppState.shared.pasteService.paste(with: clip)
    }

    @MainActor
    @objc func selectSnippetMenuItem(_ sender: AnyObject) {
        CPYUtilities.sendCustomLog(with: "selectSnippetMenuItem")
        guard let primaryKey = sender.representedObject as? String else {
            CPYUtilities.sendCustomLog(with: "Cannot fetch snippet primary key")
            NSSound.beep()
            return
        }
        guard let snippet = PersistenceController.shared.fetchSnippet(byIdentifier: primaryKey) else {
            CPYUtilities.sendCustomLog(with: "Cannot fetch snippet data")
            NSSound.beep()
            return
        }
        AppState.shared.pasteService.copyToPasteboard(with: snippet.content)
        AppState.shared.pasteService.paste()
    }

    func terminateApplication() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Login Item Methods
    private func promptToAddLoginItems() {
        let alert = NSAlert()
        alert.messageText = L10n.launchHakoOnSystemStartup
        alert.informativeText = L10n.youCanChangeThisSettingInThePreferencesIfYouWant
        alert.addButton(withTitle: L10n.launchOnSystemStartup)
        alert.addButton(withTitle: L10n.donTLaunch)
        alert.showsSuppressionButton = true
        NSApp.activate(ignoringOtherApps: true)

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            AppState.shared.defaults.set(true, forKey: Constants.UserDefaults.loginItem)
            AppState.shared.defaults.synchronize()
            reflectLoginItemState()
        }
        if alert.suppressionButton?.state == NSControl.StateValue.on {
            AppState.shared.defaults.set(true, forKey: Constants.UserDefaults.suppressAlertForLoginItem)
            AppState.shared.defaults.synchronize()
        }
    }

    private func toggleAddingToLoginItems(_ isEnable: Bool) {
        let appService = SMAppService.mainApp
        do {
            if isEnable {
                try appService.register()
            } else {
                try appService.unregister()
            }
        } catch {
            CPYUtilities.sendCustomLog(with: "Failed to update login item: \(error)")
        }
    }

    private func reflectLoginItemState() {
        let isInLoginItems = AppState.shared.defaults.bool(forKey: Constants.UserDefaults.loginItem)
        toggleAddingToLoginItems(isInLoginItems)
    }
}

// MARK: - NSApplication Delegate
extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // UserDefaults
        CPYUtilities.registerUserDefaultKeys()
        // SDKs
        CPYUtilities.initSDKs()
        // Check Accessibility Permission
        AppState.shared.accessibilityService.isAccessibilityEnabled(isPrompt: true)

        // Migrate Realm data to SwiftData (one-time)
        RealmMigrator.migrateIfNeeded(context: PersistenceController.shared.mainContext)

        // Show Login Item
        if !AppState.shared.defaults.bool(forKey: Constants.UserDefaults.loginItem) && !AppState.shared.defaults.bool(forKey: Constants.UserDefaults.suppressAlertForLoginItem) {
            promptToAddLoginItems()
        }

        // Sparkle 2.x
        updaterController.updater.automaticallyChecksForUpdates = AppState.shared.defaults.bool(forKey: Constants.Update.enableAutomaticCheck)
        updaterController.updater.updateCheckInterval = TimeInterval(AppState.shared.defaults.integer(forKey: Constants.Update.checkInterval))
        updaterController.startUpdater()

        // Binding Events
        bind()

        // Services
        AppState.shared.clipService.startMonitoring()
        AppState.shared.dataCleanService.startMonitoring()
        AppState.shared.excludeAppService.startMonitoring()
        AppState.shared.hotKeyService.setupDefaultHotKeys()

        // Managers
        AppState.shared.menuManager.setup()
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        #if RELEASE
            MoveToApplications.moveIfNecessary()
        #endif
    }

}

// MARK: - Bind
private extension AppDelegate {
    func bind() {
        // Login Item
        UserDefaults.standard
            .publisher(for: \.kCPYLoginItem)
            .compactMap { $0 as? Bool }
            .sink { [weak self] _ in
                self?.reflectLoginItemState()
            }
            .store(in: &cancellables)
        // Observe Screenshot setting
        UserDefaults.standard
            .publisher(for: \.kCPYBetaObserveScreenshot)
            .compactMap { $0 as? Bool }
            .sink { [weak self] enabled in
                self?.screenshotObserver.isEnabled = enabled
            }
            .store(in: &cancellables)
        // Observe Screenshot image
        screenshotObserver.addedImagePublisher
            .sink { image in
                AppState.shared.clipService.create(with: image)
            }
            .store(in: &cancellables)
    }
}

// MARK: - KVO keys for UserDefaults
private extension UserDefaults {
    @objc var kCPYLoginItem: Any? {
        return object(forKey: "loginItem")
    }
    @objc var kCPYBetaObserveScreenshot: Any? {
        return object(forKey: "kCPYBetaObserveScreenshot")
    }
}
