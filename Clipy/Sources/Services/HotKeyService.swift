//
//  HotKeyService.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/11/19.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Cocoa
import Magnet

final class HotKeyService: NSObject {

    // MARK: - Properties
    static var defaultKeyCombos: [String: Any] = {
        return [Constants.Menu.clip: ["keyCode": 9, "modifiers": 768],
                Constants.Menu.history: ["keyCode": 9, "modifiers": 4352],
                Constants.Menu.snippet: ["keyCode": 11, "modifiers": 768]]
    }()

    fileprivate(set) var mainKeyCombo: KeyCombo?
    fileprivate(set) var historyKeyCombo: KeyCombo?
    fileprivate(set) var snippetKeyCombo: KeyCombo?
    fileprivate(set) var clearHistoryKeyCombo: KeyCombo?

}

// MARK: - Actions
extension HotKeyService {
    @objc func popupMainMenu() {
        AppState.shared.menuManager.popUpMenu(.main)
    }

    @objc func popupHistoryMenu() {
        AppState.shared.menuManager.popUpMenu(.history)
    }

    @objc func popUpSnippetMenu() {
        AppState.shared.menuManager.popUpMenu(.snippet)
    }

    @MainActor @objc func popUpClearHistoryAlert() {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.clearAllHistory()
    }
}

// MARK: - Setup
extension HotKeyService {
    func setupDefaultHotKeys() {
        // Migration new framework
        if !AppState.shared.defaults.bool(forKey: Constants.HotKey.migrateNewKeyCombo) {
            migrationKeyCombos()
            AppState.shared.defaults.set(true, forKey: Constants.HotKey.migrateNewKeyCombo)
            AppState.shared.defaults.synchronize()
        }
        // Snippet hotkey
        setupSnippetHotKeys()

        // Main menu
        change(with: .main, keyCombo: savedKeyCombo(forKey: Constants.HotKey.mainKeyCombo))
        // History menu
        change(with: .history, keyCombo: savedKeyCombo(forKey: Constants.HotKey.historyKeyCombo))
        // Snippet menu
        change(with: .snippet, keyCombo: savedKeyCombo(forKey: Constants.HotKey.snippetKeyCombo))
        // Clear History
        changeClearHistoryKeyCombo(savedKeyCombo(forKey: Constants.HotKey.clearHistoryKeyCombo))
    }

    func change(with type: MenuType, keyCombo: KeyCombo?) {
        switch type {
        case .main:
            mainKeyCombo = keyCombo
        case .history:
            historyKeyCombo = keyCombo
        case .snippet:
            snippetKeyCombo = keyCombo
        }
        register(with: type, keyCombo: keyCombo)
    }

    func changeClearHistoryKeyCombo(_ keyCombo: KeyCombo?) {
        clearHistoryKeyCombo = keyCombo
        AppState.shared.defaults.set(keyCombo?.archive(), forKey: Constants.HotKey.clearHistoryKeyCombo)
        AppState.shared.defaults.synchronize()
        HotKeyCenter.shared.unregisterHotKey(with: "ClearHistory")
        guard let keyCombo = keyCombo else { return }
        let hotkey = HotKey(identifier: "ClearHistory", keyCombo: keyCombo, target: self, action: #selector(HotKeyService.popUpClearHistoryAlert))
        hotkey.register()
    }

    private func savedKeyCombo(forKey key: String) -> KeyCombo? {
        guard let data = AppState.shared.defaults.object(forKey: key) as? Data else { return nil }
        guard let keyCombo = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? KeyCombo else { return nil }
        return keyCombo
    }
}

// MARK: - Register
private extension HotKeyService {
    func register(with type: MenuType, keyCombo: KeyCombo?) {
        save(with: type, keyCombo: keyCombo)
        HotKeyCenter.shared.unregisterHotKey(with: type.rawValue)
        guard let keyCombo = keyCombo else { return }
        let hotKey = HotKey(identifier: type.rawValue, keyCombo: keyCombo, target: self, action: type.hotKeySelector)
        hotKey.register()
    }

    func save(with type: MenuType, keyCombo: KeyCombo?) {
        AppState.shared.defaults.set(keyCombo?.archive(), forKey: type.userDefaultsKey)
        AppState.shared.defaults.synchronize()
    }
}

// MARK: - Migration
fileprivate extension HotKeyService {
    fileprivate func migrationKeyCombos() {
        guard let keyCombos = AppState.shared.defaults.object(forKey: Constants.UserDefaults.hotKeys) as? [String: Any] else { return }

        if let (keyCode, modifiers) = parse(with: keyCombos, forKey: Constants.Menu.clip) {
            if let keyCombo = KeyCombo(QWERTYKeyCode: keyCode, carbonModifiers: modifiers) {
                AppState.shared.defaults.set(keyCombo.archive(), forKey: Constants.HotKey.mainKeyCombo)
            }
        }
        if let (keyCode, modifiers) = parse(with: keyCombos, forKey: Constants.Menu.history) {
            if let keyCombo = KeyCombo(QWERTYKeyCode: keyCode, carbonModifiers: modifiers) {
                AppState.shared.defaults.set(keyCombo.archive(), forKey: Constants.HotKey.historyKeyCombo)
            }
        }
        if let (keyCode, modifiers) = parse(with: keyCombos, forKey: Constants.Menu.snippet) {
            if let keyCombo = KeyCombo(QWERTYKeyCode: keyCode, carbonModifiers: modifiers) {
                AppState.shared.defaults.set(keyCombo.archive(), forKey: Constants.HotKey.snippetKeyCombo)
            }
        }
    }

    private func parse(with keyCombos: [String: Any], forKey key: String) -> (Int, Int)? {
        guard let combos = keyCombos[key] as? [String: Any] else { return nil }
        guard let keyCode = combos["keyCode"] as? Int, let modifiers = combos["modifiers"] as? Int else { return nil }
        return (keyCode, modifiers)
    }
}

// MARK: - Snippet HotKey
extension HotKeyService {
    private var folderKeyCombos: [String: KeyCombo]? {
        get {
            guard let data = AppState.shared.defaults.object(forKey: Constants.HotKey.folderKeyCombos) as? Data else { return nil }
            return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: KeyCombo]
        }
        set {
            if let value = newValue {
                let data = (try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)) ?? Data()
                AppState.shared.defaults.set(data, forKey: Constants.HotKey.folderKeyCombos)
            } else {
                AppState.shared.defaults.removeObject(forKey: Constants.HotKey.folderKeyCombos)
            }
            AppState.shared.defaults.synchronize()
        }
    }

    func snippetKeyCombo(forIdentifier identifier: String) -> KeyCombo? {
        return folderKeyCombos?[identifier]
    }

    func registerSnippetHotKey(with identifier: String, keyCombo: KeyCombo) {
        unregisterSnippetHotKey(with: identifier)
        let hotKey = HotKey(identifier: identifier, keyCombo: keyCombo, target: self, action: #selector(HotKeyService.popupSnippetFolder(_:)))
        hotKey.register()
        var keyCombos = folderKeyCombos ?? [String: KeyCombo]()
        keyCombos[identifier] = keyCombo
        folderKeyCombos = keyCombos
    }

    func unregisterSnippetHotKey(with identifier: String) {
        HotKeyCenter.shared.unregisterHotKey(with: identifier)
        var keyCombos = folderKeyCombos ?? [String: KeyCombo]()
        keyCombos.removeValue(forKey: identifier)
        folderKeyCombos = keyCombos
    }

    @MainActor
    @objc func popupSnippetFolder(_ object: AnyObject) {
        guard let hotKey = object as? HotKey else { return }
        guard let folder = PersistenceController.shared.fetchFolder(byIdentifier: hotKey.identifier) else {
            unregisterSnippetHotKey(with: hotKey.identifier)
            return
        }
        if !folder.enable { return }

        AppState.shared.menuManager.popUpSnippetFolder(folder)
    }

    fileprivate func setupSnippetHotKeys() {
        folderKeyCombos?.forEach {
            let hotKey = HotKey(identifier: $0, keyCombo: $1, target: self, action: #selector(HotKeyService.popupSnippetFolder(_:)))
            hotKey.register()
        }
    }
}
