//
//  UpdatesPreferenceView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI

struct UpdatesPreferenceView: View {
    @AppStorage(Constants.Update.enableAutomaticCheck) private var enableAutoCheck = true
    @AppStorage(Constants.Update.checkInterval) private var checkInterval = 86400

    private let intervalOptions: [(String, Int)] = [
        (L10n.hourly, 3600),
        (L10n.daily, 86400),
        (L10n.weekly, 604800),
        (L10n.monthly, 2592000)
    ]

    var body: some View {
        Form {
            Section(L10n.updates) {
                HStack {
                    Text(L10n.version)
                    Spacer()
                    Text("v\(Bundle.main.appVersion ?? "")")
                        .foregroundStyle(.secondary)
                }
                Toggle(L10n.autoCheckUpdates, isOn: $enableAutoCheck)
                if enableAutoCheck {
                    Picker(L10n.checkInterval, selection: $checkInterval) {
                        ForEach(intervalOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
