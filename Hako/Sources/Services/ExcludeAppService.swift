//
//  ExcludeAppService.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2017/02/10.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Cocoa
import Combine

final class ExcludeAppService {

    // MARK: - Properties
    fileprivate(set) var applications = [AppInfo]()
    fileprivate var frontApplication: NSRunningApplication?
    fileprivate var cancellables = Set<AnyCancellable>()

    // MARK: - Initialize
    init(applications: [AppInfo]) {
        self.applications = applications
    }

}

// MARK: - Monitor Applications
extension ExcludeAppService {
    func startMonitoring() {
        cancellables.removeAll()
        // Monitoring top active application
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?["NSWorkspaceApplicationKey"] as? NSRunningApplication }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in
                self?.frontApplication = app
            }
            .store(in: &cancellables)
    }
}

// MARK: - Exclude
extension ExcludeAppService {
    func frontProcessIsExcludedApplication() -> Bool {
        if applications.isEmpty { return false }
        guard let frontApplicationIdentifier = frontApplication?.bundleIdentifier else { return false }

        for app in applications where app.identifier == frontApplicationIdentifier {
            return true
        }
        return false
    }
}

// MARK: - Add or Delete
extension ExcludeAppService {
    func add(with appInfo: AppInfo) {
        if applications.contains(appInfo) { return }
        applications.append(appInfo)
        save()
    }

    func delete(with appInfo: AppInfo) {
        applications = applications.filter { $0 != appInfo }
        save()
    }

    func delete(with index: Int) {
        delete(with: applications[index])
    }

    private func save() {
        let data = applications.archive()
        AppState.shared.defaults.set(data, forKey: Constants.UserDefaults.excludeApplications)
        AppState.shared.defaults.synchronize()
    }
}

// MARK: - Special Applications
extension ExcludeAppService {
    /**
     *  Responding to applications that have special handling for protection of passwords etc.
     *  e.g 1Password on GoogleChrome browser extension
     *
     *  ref: http://nspasteboard.org/
     */
    private enum Application: String {
        case onePassword = "com.agilebits.onepassword"

        // MARK: - Properties
        private var macApplicationIdentifiers: [String] {
            switch self {
            case .onePassword:
                return ["com.agilebits.onepassword-osx", // for 1Password 6
                        "com.agilebits.onepassword7"] // for 1Password 7
            }
        }

        // MARK: - Excluded
        func isExcluded(applications: [AppInfo]) -> Bool {
            return !applications.filter { macApplicationIdentifiers.contains($0.identifier) }.isEmpty
        }

    }

    func copiedProcessIsExcludedApplications(pasteboard: NSPasteboard) -> Bool {
        guard let types = pasteboard.types else { return false }
        guard let application = types.compactMap({ Application(rawValue: $0.rawValue) }).first else { return false }
        return application.isExcluded(applications: applications)
    }
}
