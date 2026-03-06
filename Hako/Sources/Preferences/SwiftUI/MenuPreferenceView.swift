//
//  MenuPreferenceView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI

struct MenuPreferenceView: View {
    @AppStorage(Constants.UserDefaults.maxMenuItemTitleLength) private var maxTitleLength = 20
    @AppStorage(Constants.UserDefaults.numberOfItemsPlaceInline) private var inlineItems = 0
    @AppStorage(Constants.UserDefaults.numberOfItemsPlaceInsideFolder) private var folderItems = 10
    @AppStorage(Constants.UserDefaults.menuItemsTitleStartWithZero) private var startWithZero = false
    @AppStorage(Constants.UserDefaults.showAlertBeforeClearHistory) private var showClearAlert = true
    @AppStorage(Constants.UserDefaults.addClearHistoryMenuItem) private var addClearMenuItem = true
    @AppStorage(Constants.UserDefaults.showIconInTheMenu) private var showIcon = true
    @AppStorage(Constants.UserDefaults.menuItemsAreMarkedWithNumbers) private var markWithNumbers = true
    @AppStorage(Constants.UserDefaults.addNumericKeyEquivalents) private var addKeyEquivalents = false
    @AppStorage(Constants.UserDefaults.showToolTipOnMenuItem) private var showToolTip = true
    @AppStorage(Constants.UserDefaults.showImageInTheMenu) private var showImage = true
    @AppStorage(Constants.UserDefaults.maxLengthOfToolTip) private var maxToolTipLength = 200
    @AppStorage(Constants.UserDefaults.overwriteSameHistory) private var overwriteSame = true
    @AppStorage(Constants.UserDefaults.copySameHistory) private var copySame = true
    @AppStorage(Constants.UserDefaults.showColorPreviewInTheMenu) private var showColorPreview = true

    var body: some View {
        Form {
            Section(L10n.layout) {
                Stepper(value: $maxTitleLength, in: 3...200) {
                    HStack {
                        Text(L10n.maxTitleLength)
                        Text("\(maxTitleLength)")
                            .monospacedDigit()
                    }
                }
                Stepper(value: $inlineItems, in: 0...999) {
                    HStack {
                        Text(L10n.inlineItems)
                        Text("\(inlineItems)")
                            .monospacedDigit()
                    }
                }
                Stepper(value: $folderItems, in: 1...999) {
                    HStack {
                        Text(L10n.folderItems)
                        Text("\(folderItems)")
                            .monospacedDigit()
                    }
                }
            }

            Section(L10n.display) {
                Toggle(L10n.startWithZero, isOn: $startWithZero)
                Toggle(L10n.markWithNumbers, isOn: $markWithNumbers)
                Toggle(L10n.keyEquivalents, isOn: $addKeyEquivalents)
                Toggle(L10n.showIcon, isOn: $showIcon)
                Toggle(L10n.showImage, isOn: $showImage)
                Toggle(L10n.colorPreview, isOn: $showColorPreview)
            }

            Section(L10n.tooltip) {
                Toggle(L10n.showTooltip, isOn: $showToolTip)
                if showToolTip {
                    Stepper(value: $maxToolTipLength, in: 10...10000) {
                        HStack {
                            Text(L10n.maxTooltip)
                            Text("\(maxToolTipLength)")
                                .monospacedDigit()
                        }
                    }
                }
            }

            Section(L10n.history) {
                Toggle(L10n.clearHistoryMenuItem, isOn: $addClearMenuItem)
                Toggle(L10n.clearHistoryAlert, isOn: $showClearAlert)
                Toggle(L10n.overwriteSame, isOn: $overwriteSame)
                Toggle(L10n.copySame, isOn: $copySame)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
