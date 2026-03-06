//
//  SnippetsEditorWindowController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/05/18.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa
import UniformTypeIdentifiers
import SwiftData
import KeyHolder
import Magnet

final class SnippetsEditorWindowController: NSWindowController {

    // MARK: - Properties
    static let sharedController = SnippetsEditorWindowController(windowNibName: "SnippetsEditorWindowController")
    @IBOutlet private weak var splitView: HakoSplitView!
    @IBOutlet private weak var folderSettingView: NSView!
    @IBOutlet private weak var folderTitleTextField: NSTextField!
    @IBOutlet private weak var folderShortcutRecordView: RecordView! {
        didSet {
            folderShortcutRecordView.delegate = self
        }
    }
    @IBOutlet private var textView: PlaceHolderTextView! {
        didSet {
            textView.font = NSFont.systemFont(ofSize: 14)
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.enabledTextCheckingTypes = 0
            textView.isRichText = false
            textView.placeHolderText = L10n.pleaseFillInTheContentsOfTheSnippet
        }
    }
    @IBOutlet private weak var outlineView: NSOutlineView! {
        didSet {
            outlineView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)])
        }
    }

    private var folders = [FolderItem]()
    private var selectedSnippet: SnippetItem? {
        return outlineView.item(atRow: outlineView.selectedRow) as? SnippetItem
    }
    private var selectedFolder: FolderItem? {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else { return nil }
        if let folder = outlineView.parent(forItem: item) as? FolderItem {
            return folder
        } else if let folder = item as? FolderItem {
            return folder
        }
        return nil
    }

    /// Returns snippets for a folder sorted by index
    private func sortedSnippets(for folder: FolderItem) -> [SnippetItem] {
        return folder.snippets.sorted { $0.index < $1.index }
    }

    // MARK: - Window Life Cycle
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.collectionBehavior = .canJoinAllSpaces
        self.window?.backgroundColor = NSColor(white: 0.99, alpha: 1)
        self.window?.titlebarAppearsTransparent = true

        reloadFolders()
        outlineView.reloadData()

        if let folder = folders.first {
            outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
            changeItemFocus()
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }

    @MainActor
    private func reloadFolders() {
        folders = PersistenceController.shared.fetchFolders(sortedByIndex: true)
    }
}

// MARK: - IBActions
extension SnippetsEditorWindowController {
    @MainActor
    @IBAction private func addSnippetButtonTapped(_ sender: AnyObject) {
        guard let folder = selectedFolder else {
            NSSound.beep()
            return
        }
        let snippet = SnippetItem(
            index: folder.snippets.count,
            title: "untitled snippet"
        )
        folder.snippets.append(snippet)
        PersistenceController.shared.save()
        outlineView.reloadData()
        outlineView.expandItem(folder)
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: snippet)), byExtendingSelection: false)
        changeItemFocus()
    }

    @MainActor
    @IBAction private func addFolderButtonTapped(_ sender: AnyObject) {
        let lastIndex = folders.last?.index ?? -1
        let folder = FolderItem(index: lastIndex + 1, title: "untitled folder")
        PersistenceController.shared.addFolder(folder)
        reloadFolders()
        outlineView.reloadData()
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
        changeItemFocus()
    }

    @MainActor
    @IBAction private func deleteButtonTapped(_ sender: AnyObject) {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            NSSound.beep()
            return
        }

        let alert = NSAlert()
        alert.messageText = L10n.deleteItem
        alert.informativeText = L10n.areYouSureWantToDeleteThisItem
        alert.addButton(withTitle: L10n.deleteItem)
        alert.addButton(withTitle: L10n.cancel)
        NSApp.activate(ignoringOtherApps: true)
        let result = alert.runModal()
        if result != NSApplication.ModalResponse.alertFirstButtonReturn { return }

        if let folder = item as? FolderItem {
            AppState.shared.hotKeyService.unregisterSnippetHotKey(with: folder.identifier)
            PersistenceController.shared.deleteFolder(folder)
            reloadFolders()
        } else if let snippet = item as? SnippetItem {
            if let folder = snippet.folder {
                folder.snippets.removeAll { $0.identifier == snippet.identifier }
                rearrangeSnippetIndices(for: folder)
            }
            PersistenceController.shared.deleteSnippet(snippet)
        }
        outlineView.reloadData()
        changeItemFocus()
    }

    @MainActor
    @IBAction private func changeStatusButtonTapped(_ sender: AnyObject) {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            NSSound.beep()
            return
        }
        if let folder = item as? FolderItem {
            folder.enable = !folder.enable
        } else if let snippet = item as? SnippetItem {
            snippet.enable = !snippet.enable
        }
        PersistenceController.shared.save()
        outlineView.reloadData()
        changeItemFocus()
    }

    @MainActor
    @IBAction private func importSnippetButtonTapped(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())
        panel.allowedContentTypes = [.xml]
        let returnCode = panel.runModal()

        if returnCode != NSApplication.ModalResponse.OK { return }

        guard let url = panel.urls.first else { return }
        guard let xmlData = try? Data(contentsOf: url) else { return }

        do {
            let persistence = PersistenceController.shared
            var folderIndex = (folders.last?.index ?? -1) + 1

            let xmlDocument = try XMLDocument(data: xmlData, options: [])
            guard let rootElement = xmlDocument.rootElement() else { return }
            let folderElements = rootElement.elements(forName: Constants.Xml.folderElement)

            for folderElement in folderElements {
                let title = folderElement.elements(forName: Constants.Xml.titleElement).first?.stringValue ?? "untitled folder"
                let folder = FolderItem(index: folderIndex, title: title)
                persistence.addFolder(folder)

                var snippetIndex = 0
                if let snippetsElement = folderElement.elements(forName: Constants.Xml.snippetsElement).first {
                    let snippetElements = snippetsElement.elements(forName: Constants.Xml.snippetElement)
                    for snippetElement in snippetElements {
                        let snippetTitle = snippetElement.elements(forName: Constants.Xml.titleElement).first?.stringValue ?? "untitled snippet"
                        let content = snippetElement.elements(forName: Constants.Xml.contentElement).first?.stringValue ?? ""
                        let snippet = SnippetItem(index: snippetIndex, title: snippetTitle, content: content)
                        folder.snippets.append(snippet)
                        snippetIndex += 1
                    }
                }
                persistence.save()
                folderIndex += 1
            }
            reloadFolders()
            outlineView.reloadData()
        } catch {
            NSSound.beep()
        }
    }

    @MainActor
    @IBAction private func exportSnippetButtonTapped(_ sender: AnyObject) {
        let rootElement = XMLElement(name: Constants.Xml.rootElement)
        let xmlDocument = XMLDocument(rootElement: rootElement)

        let allFolders = PersistenceController.shared.fetchFolders(sortedByIndex: true)
        allFolders.forEach { folder in
            let folderElement = XMLElement(name: Constants.Xml.folderElement)
            rootElement.addChild(folderElement)

            let titleElement = XMLElement(name: Constants.Xml.titleElement, stringValue: folder.title)
            folderElement.addChild(titleElement)

            let snippetsElement = XMLElement(name: Constants.Xml.snippetsElement)
            folderElement.addChild(snippetsElement)
            folder.sortedSnippets.forEach { snippet in
                let snippetElement = XMLElement(name: Constants.Xml.snippetElement)
                snippetsElement.addChild(snippetElement)
                let snippetTitleElement = XMLElement(name: Constants.Xml.titleElement, stringValue: snippet.title)
                snippetElement.addChild(snippetTitleElement)
                let contentElement = XMLElement(name: Constants.Xml.contentElement, stringValue: snippet.content)
                snippetElement.addChild(contentElement)
            }
        }

        let panel = NSSavePanel()
        panel.accessoryView = nil
        panel.canSelectHiddenExtension = true
        panel.allowedContentTypes = [.xml]
        panel.allowsOtherFileTypes = false
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())
        panel.nameFieldStringValue = "snippets"
        let returnCode = panel.runModal()

        if returnCode != NSApplication.ModalResponse.OK { return }

        let data = xmlDocument.xmlData(options: [.nodePrettyPrint])
        guard !data.isEmpty, let saveURL = panel.url else { return }

        do {
            try data.write(to: saveURL, options: .atomic)
        } catch {
            NSSound.beep()
        }
    }
}

// MARK: - Item Selected
private extension SnippetsEditorWindowController {
    func changeItemFocus() {
        textView.undoManager?.removeAllActions()
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            folderSettingView.isHidden = true
            textView.isHidden = true
            folderShortcutRecordView.keyCombo = nil
            folderTitleTextField.stringValue = ""
            return
        }
        if let folder = item as? FolderItem {
            textView.string = ""
            folderTitleTextField.stringValue = folder.title
            folderShortcutRecordView.keyCombo = AppState.shared.hotKeyService.snippetKeyCombo(forIdentifier: folder.identifier)
            folderSettingView.isHidden = false
            textView.isHidden = true
        } else if let snippet = item as? SnippetItem {
            textView.string = snippet.content
            folderTitleTextField.stringValue = ""
            folderShortcutRecordView.keyCombo = nil
            folderSettingView.isHidden = true
            textView.isHidden = false
        }
    }
}

// MARK: - Index Management
private extension SnippetsEditorWindowController {
    @MainActor
    func rearrangeFolderIndices() {
        for (i, folder) in folders.enumerated() {
            folder.index = i
        }
        PersistenceController.shared.save()
    }

    @MainActor
    func rearrangeSnippetIndices(for folder: FolderItem) {
        for (i, snippet) in sortedSnippets(for: folder).enumerated() {
            snippet.index = i
        }
        PersistenceController.shared.save()
    }
}

// MARK: - NSSplitView Delegate
extension SnippetsEditorWindowController: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return proposedMinimumPosition + 150
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return proposedMaximumPosition / 2
    }
}

// MARK: - NSOutlineView DataSource
extension SnippetsEditorWindowController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return folders.count
        } else if let folder = item as? FolderItem {
            return folder.snippets.count
        }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let folder = item as? FolderItem {
            return !folder.snippets.isEmpty
        }
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return folders[index]
        } else if let folder = item as? FolderItem {
            return sortedSnippets(for: folder)[index]
        }
        return ""
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let folder = item as? FolderItem {
            return folder.title
        } else if let snippet = item as? SnippetItem {
            return snippet.title
        }
        return ""
    }

    // MARK: - Drag and Drop
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pasteboardItem = NSPasteboardItem()
        if let folder = item as? FolderItem, let index = folders.firstIndex(where: { $0.identifier == folder.identifier }) {
            let draggedData = DraggedData(type: .folder, folderIdentifier: folder.identifier, snippetIdentifier: nil, index: index)
            let data = (try? NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: false)) ?? Data()
            pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType))
        } else if let snippet = item as? SnippetItem, let folder = outlineView.parent(forItem: snippet) as? FolderItem {
            let sorted = sortedSnippets(for: folder)
            guard let index = sorted.firstIndex(where: { $0.identifier == snippet.identifier }) else { return nil }
            let draggedData = DraggedData(type: .snippet, folderIdentifier: folder.identifier, snippetIdentifier: snippet.identifier, index: index)
            let data = (try? NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: false)) ?? Data()
            pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType))
        } else {
            return nil
        }
        return pasteboardItem
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        let pasteboard = info.draggingPasteboard
        guard let data = pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)) else { return NSDragOperation() }
        guard let draggedData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: DraggedData.self, from: data) else { return NSDragOperation() }

        switch draggedData.type {
        case .folder where item == nil:
            return .move
        case .snippet where item is FolderItem:
            return .move
        default:
            return NSDragOperation()
        }
    }

    @MainActor
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pasteboard = info.draggingPasteboard
        guard let data = pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)) else { return false }
        guard let draggedData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: DraggedData.self, from: data) else { return false }

        switch draggedData.type {
        case .folder where index != draggedData.index:
            guard index >= 0 else { return false }
            guard let folder = folders.first(where: { $0.identifier == draggedData.folderIdentifier }) else { return false }
            folders.insert(folder, at: index)
            let removedIndex = (index < draggedData.index) ? draggedData.index + 1 : draggedData.index
            folders.remove(at: removedIndex)
            rearrangeFolderIndices()
            outlineView.reloadData()
            outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
            changeItemFocus()
            return true
        case .snippet:
            guard let fromFolder = folders.first(where: { $0.identifier == draggedData.folderIdentifier }) else { return false }
            guard let toFolder = item as? FolderItem else { return false }
            let fromSorted = sortedSnippets(for: fromFolder)
            guard let snippet = fromSorted.first(where: { $0.identifier == draggedData.snippetIdentifier }) else { return false }

            if fromFolder.identifier == toFolder.identifier {
                guard index >= 0, index != draggedData.index else { return false }
                // Reorder within same folder
                var sorted = fromSorted
                sorted.insert(snippet, at: index)
                let removedIndex = (index < draggedData.index) ? draggedData.index + 1 : draggedData.index
                sorted.remove(at: removedIndex)
                for (i, s) in sorted.enumerated() { s.index = i }
                PersistenceController.shared.save()
                outlineView.reloadData()
                outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: snippet)), byExtendingSelection: false)
                changeItemFocus()
                return true
            } else {
                // Move to other folder
                let targetIndex = max(0, index)
                // Remove from source
                fromFolder.snippets.removeAll { $0.identifier == snippet.identifier }
                rearrangeSnippetIndices(for: fromFolder)
                // Add to target — shift existing indices at targetIndex and beyond
                for s in toFolder.snippets where s.index >= targetIndex {
                    s.index += 1
                }
                snippet.index = targetIndex
                toFolder.snippets.append(snippet)
                PersistenceController.shared.save()
                outlineView.reloadData()
                outlineView.expandItem(toFolder)
                outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: snippet)), byExtendingSelection: false)
                changeItemFocus()
                return true
            }
        default: return false
        }
    }
}

// MARK: - NSOutlineView Delegate
extension SnippetsEditorWindowController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, item: Any) {
        guard let cell = cell as? SnippetsEditorCell else { return }
        if let folder = item as? FolderItem {
            cell.iconType = .folder
            cell.isItemEnabled = folder.enable
        } else if let snippet = item as? SnippetItem {
            cell.iconType = .none
            cell.isItemEnabled = snippet.enable
        }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        changeItemFocus()
    }

    @MainActor
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let text = fieldEditor.string
        guard !text.isEmpty else { return false }
        guard let outlineView = control as? NSOutlineView else { return false }
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else { return false }
        if let folder = item as? FolderItem {
            folder.title = text
        } else if let snippet = item as? SnippetItem {
            snippet.title = text
        }
        PersistenceController.shared.save()
        changeItemFocus()
        return true
    }
}

// MARK: - NSTextView Delegate
extension SnippetsEditorWindowController: NSTextViewDelegate {
    @MainActor
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let replacementString = replacementString else { return false }
        let text = textView.string
        guard let snippet = selectedSnippet else { return false }
        let string = (text as NSString).replacingCharacters(in: affectedCharRange, with: replacementString)
        snippet.content = string
        PersistenceController.shared.save()
        return true
    }
}

// MARK: - RecordView Delegate
extension SnippetsEditorWindowController: RecordViewDelegate {
    func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
        return selectedFolder != nil
    }

    func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
        return selectedFolder != nil
    }

    func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
        guard let selectedFolder = selectedFolder else { return }
        if let keyCombo = keyCombo {
            AppState.shared.hotKeyService.registerSnippetHotKey(with: selectedFolder.identifier, keyCombo: keyCombo)
        } else {
            AppState.shared.hotKeyService.unregisterSnippetHotKey(with: selectedFolder.identifier)
        }
    }

    func recordViewDidEndRecording(_ recordView: RecordView) {}
}
