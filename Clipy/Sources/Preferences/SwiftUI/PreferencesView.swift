//
//  PreferencesView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI

struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralPreferenceView()
                .tabItem { Label(L10n.general, systemImage: "gear") }
                .tag(0)
            MenuPreferenceView()
                .tabItem { Label(L10n.menu, systemImage: "list.bullet") }
                .tag(1)
            TypePreferenceView()
                .tabItem { Label(L10n.type, systemImage: "doc.on.clipboard") }
                .tag(2)
            ExcludeAppPreferenceView()
                .tabItem { Label(L10n.excludeApp, systemImage: "xmark.app") }
                .tag(3)
            ShortcutsPreferenceView()
                .tabItem { Label(L10n.shortcuts, systemImage: "keyboard") }
                .tag(4)
            UpdatesPreferenceView()
                .tabItem { Label(L10n.updates, systemImage: "arrow.triangle.2.circlepath") }
                .tag(5)
            BetaPreferenceView()
                .tabItem { Label(L10n.beta, systemImage: "flask") }
                .tag(6)
        }
        .frame(minWidth: 500)
    }
}
