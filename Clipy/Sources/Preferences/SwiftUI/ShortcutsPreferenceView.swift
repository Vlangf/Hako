//
//  ShortcutsPreferenceView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI
import Magnet
import KeyHolder

/// NSViewRepresentable wrapper for KeyHolder's RecordView
struct KeyRecordView: NSViewRepresentable {
    @Binding var keyCombo: KeyCombo?
    var onChange: ((KeyCombo?) -> Void)?

    func makeNSView(context: Context) -> RecordView {
        let view = RecordView(frame: .zero)
        view.delegate = context.coordinator
        view.keyCombo = keyCombo
        return view
    }

    func updateNSView(_ nsView: RecordView, context: Context) {
        nsView.keyCombo = keyCombo
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, RecordViewDelegate {
        var parent: KeyRecordView

        init(_ parent: KeyRecordView) {
            self.parent = parent
        }

        func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool { true }
        func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool { true }
        func recordViewDidEndRecording(_ recordView: RecordView) {}

        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            parent.keyCombo = keyCombo
            parent.onChange?(keyCombo)
        }
    }
}

struct ShortcutsPreferenceView: View {
    @State private var mainKeyCombo: KeyCombo? = AppState.shared.hotKeyService.mainKeyCombo
    @State private var historyKeyCombo: KeyCombo? = AppState.shared.hotKeyService.historyKeyCombo
    @State private var snippetKeyCombo: KeyCombo? = AppState.shared.hotKeyService.snippetKeyCombo
    @State private var clearHistoryKeyCombo: KeyCombo? = AppState.shared.hotKeyService.clearHistoryKeyCombo

    var body: some View {
        Form {
            Section(L10n.shortcuts) {
                HStack {
                    Text(L10n.mainMenu)
                    Spacer()
                    KeyRecordView(keyCombo: $mainKeyCombo) { combo in
                        AppState.shared.hotKeyService.change(with: .main, keyCombo: combo)
                    }
                    .frame(width: 200, height: 24)
                }
                HStack {
                    Text(L10n.history)
                    Spacer()
                    KeyRecordView(keyCombo: $historyKeyCombo) { combo in
                        AppState.shared.hotKeyService.change(with: .history, keyCombo: combo)
                    }
                    .frame(width: 200, height: 24)
                }
                HStack {
                    Text(L10n.snippet)
                    Spacer()
                    KeyRecordView(keyCombo: $snippetKeyCombo) { combo in
                        AppState.shared.hotKeyService.change(with: .snippet, keyCombo: combo)
                    }
                    .frame(width: 200, height: 24)
                }
                HStack {
                    Text(L10n.clearHistory)
                    Spacer()
                    KeyRecordView(keyCombo: $clearHistoryKeyCombo) { combo in
                        AppState.shared.hotKeyService.changeClearHistoryKeyCombo(combo)
                    }
                    .frame(width: 200, height: 24)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
