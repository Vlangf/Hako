//
//  AppState.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Observation

@Observable
final class AppState {
    static let shared = AppState()

    let clipService: ClipService
    let hotKeyService: HotKeyService
    let dataCleanService: DataCleanService
    let pasteService: PasteService
    let excludeAppService: ExcludeAppService
    let accessibilityService: AccessibilityService
    let menuManager: MenuManager
    let defaults: UserDefaults

    private init() {
        self.clipService = ClipService()
        self.hotKeyService = HotKeyService()
        self.dataCleanService = DataCleanService()
        self.pasteService = PasteService()
        self.accessibilityService = AccessibilityService()
        self.menuManager = MenuManager()
        self.defaults = .standard

        // Load excluded applications from storage
        var excludeApplications = [CPYAppInfo]()
        if let data = defaults.object(forKey: Constants.UserDefaults.excludeApplications) as? Data,
           let applications = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [CPYAppInfo] {
            excludeApplications = applications
        }
        self.excludeAppService = ExcludeAppService(applications: excludeApplications)
    }
}
