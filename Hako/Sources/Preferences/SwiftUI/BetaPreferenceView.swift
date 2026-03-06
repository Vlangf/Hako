//
//  BetaPreferenceView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI

struct BetaPreferenceView: View {
    @AppStorage(Constants.Beta.pastePlainText) private var pastePlainText = true
    @AppStorage(Constants.Beta.pastePlainTextModifier) private var pastePlainTextModifier = 0
    @AppStorage(Constants.Beta.deleteHistory) private var deleteHistory = false
    @AppStorage(Constants.Beta.deleteHistoryModifier) private var deleteHistoryModifier = 0
    @AppStorage(Constants.Beta.pasteAndDeleteHistory) private var pasteAndDeleteHistory = false
    @AppStorage(Constants.Beta.pasteAndDeleteHistoryModifier) private var pasteAndDeleteHistoryModifier = 0
    @AppStorage(Constants.Beta.observerScreenshot) private var observeScreenshot = false

    private let modifierOptions = [
        (L10n.command, 0),
        (L10n.shift, 1),
        (L10n.control, 2),
        (L10n.option, 3)
    ]

    var body: some View {
        Form {
            Section(L10n.pasteAsPlainText) {
                Toggle(L10n.pastePlainText, isOn: $pastePlainText)
                if pastePlainText {
                    Picker(L10n.pastePlainModifier, selection: $pastePlainTextModifier) {
                        ForEach(modifierOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }
            }

            Section(L10n.deleteHistory) {
                Toggle(L10n.deleteAfterPaste, isOn: $deleteHistory)
                if deleteHistory {
                    Picker(L10n.pastePlainModifier, selection: $deleteHistoryModifier) {
                        ForEach(modifierOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }
            }

            Section(L10n.pasteAndDelete) {
                Toggle(L10n.pasteAndDeleteHistory, isOn: $pasteAndDeleteHistory)
                if pasteAndDeleteHistory {
                    Picker(L10n.pastePlainModifier, selection: $pasteAndDeleteHistoryModifier) {
                        ForEach(modifierOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }
            }

            Section(L10n.screenshot) {
                Toggle(L10n.observeScreenshots, isOn: $observeScreenshot)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
