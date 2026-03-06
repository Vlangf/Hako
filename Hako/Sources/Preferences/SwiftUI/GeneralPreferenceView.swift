//
//  GeneralPreferenceView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI

struct GeneralPreferenceView: View {
    @AppStorage(Constants.UserDefaults.loginItem) private var loginItem = false
    @AppStorage(Constants.UserDefaults.maxHistorySize) private var maxHistorySize = 30
    @AppStorage(Constants.UserDefaults.showStatusItem) private var showStatusItem = 1
    @AppStorage(Constants.UserDefaults.inputPasteCommand) private var inputPasteCommand = true
    @AppStorage(Constants.UserDefaults.reorderClipsAfterPasting) private var reorderClipsAfterPasting = true

    var body: some View {
        Form {
            Section(L10n.general) {
                Toggle(L10n.loginItem, isOn: $loginItem)
                Stepper(value: $maxHistorySize, in: 1...999) {
                    HStack {
                        Text(L10n.maxHistorySize)
                        Text("\(maxHistorySize)")
                            .monospacedDigit()
                    }
                }
            }

            Section(L10n.statusBar) {
                Picker(L10n.showStatusBarIcon, selection: $showStatusItem) {
                    Text(L10n.none).tag(0)
                    Text(L10n.black).tag(1)
                    Text(L10n.white).tag(2)
                }
            }

            Section(L10n.paste) {
                Toggle(L10n.inputPasteCommand, isOn: $inputPasteCommand)
                Toggle(L10n.reorderClips, isOn: $reorderClipsAfterPasting)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
