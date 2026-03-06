//
//  TypePreferenceView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI

struct TypePreferenceView: View {
    @State private var storeTypes: [String: Bool] = {
        let defaults = UserDefaults.standard
        guard let dict = defaults.object(forKey: Constants.UserDefaults.storeTypes) as? [String: NSNumber] else {
            return [:]
        }
        return dict.mapValues { $0.boolValue }
    }()

    var body: some View {
        Form {
            Section(L10n.type) {
                ForEach(ClipData.availableTypesString.sorted(), id: \.self) { type in
                    Toggle(type, isOn: binding(for: type))
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
        .onChange(of: storeTypes) {
            let nsDict = storeTypes.mapValues { NSNumber(value: $0) }
            UserDefaults.standard.set(nsDict, forKey: Constants.UserDefaults.storeTypes)
        }
    }

    private func binding(for key: String) -> Binding<Bool> {
        Binding(
            get: { storeTypes[key] ?? true },
            set: { storeTypes[key] = $0 }
        )
    }
}
