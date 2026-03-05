//
//  ExcludeAppPreferenceView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExcludeAppPreferenceView: View {
    @State private var selectedIndex: Int?
    @State private var applications: [CPYAppInfo] = AppState.shared.excludeAppService.applications

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.excludedApps)
                .font(.headline)

            List(selection: $selectedIndex) {
                ForEach(Array(applications.enumerated()), id: \.offset) { index, app in
                    Text(app.name)
                        .tag(index)
                }
            }
            .frame(minHeight: 200)

            HStack {
                Button(L10n.add) {
                    addApplication()
                }
                Button(role: .destructive) {
                    deleteSelected()
                } label: {
                    Text(L10n.deleteItem)
                }
                .disabled(selectedIndex == nil)
            }
        }
        .padding()
        .frame(width: 450)
    }

    private func addApplication() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.application]
        openPanel.allowsMultipleSelection = true
        openPanel.resolvesAliases = true
        openPanel.prompt = L10n.add
        let directories = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .localDomainMask, true)
        let basePath = directories.first ?? NSHomeDirectory()
        openPanel.directoryURL = URL(fileURLWithPath: basePath)

        guard openPanel.runModal() == .OK else { return }

        for url in openPanel.urls {
            guard let bundle = Bundle(url: url), let info = bundle.infoDictionary else { continue }
            guard let appInfo = CPYAppInfo(info: info as [String: AnyObject]) else { continue }
            AppState.shared.excludeAppService.add(with: appInfo)
        }
        applications = AppState.shared.excludeAppService.applications
    }

    private func deleteSelected() {
        guard let index = selectedIndex, index < applications.count else { return }
        AppState.shared.excludeAppService.delete(with: index)
        applications = AppState.shared.excludeAppService.applications
        selectedIndex = nil
    }
}
