import Testing
import Foundation
import Magnet
import Carbon
@testable import Clipy

@Suite("HotKeyService Tests")
struct HotKeyServiceTests {

    private func cleanupDefaults() {
        let defaults = AppState.shared.defaults
        defaults.removeObject(forKey: Constants.UserDefaults.hotKeys)
        defaults.removeObject(forKey: Constants.HotKey.migrateNewKeyCombo)
        defaults.removeObject(forKey: Constants.HotKey.mainKeyCombo)
        defaults.removeObject(forKey: Constants.HotKey.historyKeyCombo)
        defaults.removeObject(forKey: Constants.HotKey.snippetKeyCombo)
        defaults.removeObject(forKey: Constants.HotKey.clearHistoryKeyCombo)
        defaults.removeObject(forKey: Constants.HotKey.folderKeyCombos)
        defaults.synchronize()
    }

    @Test("Migrate default hotkey settings")
    @MainActor func migrateDefaultSettings() {
        cleanupDefaults()
        defer { cleanupDefaults() }

        // Set up legacy hotkey data for migration
        let defaults = AppState.shared.defaults
        defaults.set(HotKeyService.defaultKeyCombos, forKey: Constants.UserDefaults.hotKeys)
        defaults.synchronize()

        let service = HotKeyService()
        #expect(service.mainKeyCombo == nil)
        #expect(service.historyKeyCombo == nil)
        #expect(service.snippetKeyCombo == nil)
        #expect(defaults.bool(forKey: Constants.HotKey.migrateNewKeyCombo) == false)

        service.setupDefaultHotKeys()
        #expect(defaults.bool(forKey: Constants.HotKey.migrateNewKeyCombo) == true)

        #expect(service.mainKeyCombo != nil)
        #expect(service.historyKeyCombo != nil)
        #expect(service.snippetKeyCombo != nil)
    }

    @Test("Default key combos values")
    func defaultKeyCombos() {
        let keyCombos = HotKeyService.defaultKeyCombos
        let mainCombos = keyCombos[Constants.Menu.clip] as? [String: Int]
        let historyCombos = keyCombos[Constants.Menu.history] as? [String: Int]
        let snippetCombos = keyCombos[Constants.Menu.snippet] as? [String: Int]

        #expect(mainCombos?["keyCode"] == 9)
        #expect(mainCombos?["modifiers"] == 768)
        #expect(historyCombos?["keyCode"] == 9)
        #expect(historyCombos?["modifiers"] == 4352)
        #expect(snippetCombos?["keyCode"] == 11)
        #expect(snippetCombos?["modifiers"] == 768)
    }

    @Test("Save and restore key combos")
    @MainActor func saveKeyCombos() {
        cleanupDefaults()
        defer { cleanupDefaults() }

        let defaults = AppState.shared.defaults
        defaults.set(true, forKey: Constants.HotKey.migrateNewKeyCombo)
        defaults.synchronize()

        let service = HotKeyService()
        service.setupDefaultHotKeys()
        // No legacy data and migration already done → combos should be nil
        #expect(service.mainKeyCombo == nil)
        #expect(service.historyKeyCombo == nil)
        #expect(service.snippetKeyCombo == nil)

        let mainKeyCombo = KeyCombo(QWERTYKeyCode: 9, carbonModifiers: 768)
        service.change(with: .main, keyCombo: mainKeyCombo)
        #expect(service.mainKeyCombo != nil)
        #expect(service.mainKeyCombo?.QWERTYKeyCode == 9)

        service.change(with: .main, keyCombo: nil)
        #expect(service.mainKeyCombo == nil)
    }

    @Test("Clear history hotkey")
    @MainActor func clearHistoryHotKey() {
        cleanupDefaults()
        defer { cleanupDefaults() }

        let service = HotKeyService()
        #expect(service.clearHistoryKeyCombo == nil)

        let keyCombo = KeyCombo(QWERTYKeyCode: 10, carbonModifiers: cmdKey)
        service.changeClearHistoryKeyCombo(keyCombo)
        #expect(service.clearHistoryKeyCombo != nil)
        #expect(service.clearHistoryKeyCombo == keyCombo)

        service.changeClearHistoryKeyCombo(nil)
        #expect(service.clearHistoryKeyCombo == nil)
    }

    @Test("Register and unregister folder hotkeys")
    @MainActor func folderHotKeys() {
        cleanupDefaults()
        defer { cleanupDefaults() }

        let service = HotKeyService()
        let identifier = UUID().uuidString
        #expect(service.snippetKeyCombo(forIdentifier: identifier) == nil)

        let keyCombo = KeyCombo(QWERTYKeyCode: 0, carbonModifiers: cmdKey)!
        service.registerSnippetHotKey(with: identifier, keyCombo: keyCombo)
        #expect(service.snippetKeyCombo(forIdentifier: identifier) != nil)
        #expect(service.snippetKeyCombo(forIdentifier: identifier) == keyCombo)

        service.unregisterSnippetHotKey(with: identifier)
        #expect(service.snippetKeyCombo(forIdentifier: identifier) == nil)
    }
}
