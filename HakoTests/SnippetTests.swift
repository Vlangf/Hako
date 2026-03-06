import Testing
import Foundation
import SwiftData
@testable import Hako

@Suite("Snippet Tests")
@MainActor
struct SnippetTests {

    private func makePersistence() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }

    @Test("Create and fetch snippet")
    func createSnippet() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Folder")
        let snippet = SnippetItem(index: 0, title: "Test Snippet", content: "Hello")
        folder.snippets.append(snippet)
        persistence.addFolder(folder)

        let fetched = persistence.fetchSnippet(byIdentifier: snippet.identifier)
        #expect(fetched != nil)
        #expect(fetched?.title == "Test Snippet")
        #expect(fetched?.content == "Hello")
        #expect(fetched?.enable == true)
    }

    @Test("Update snippet content")
    func updateContent() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Folder")
        let snippet = SnippetItem(index: 0, title: "Snippet", content: "Original")
        folder.snippets.append(snippet)
        persistence.addFolder(folder)

        snippet.content = "Updated content"
        snippet.title = "New Title"
        persistence.save()

        let fetched = persistence.fetchSnippet(byIdentifier: snippet.identifier)
        #expect(fetched?.content == "Updated content")
        #expect(fetched?.title == "New Title")
    }

    @Test("Delete snippet from folder")
    func deleteSnippet() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Folder")
        let snippet = SnippetItem(index: 0, title: "To Delete")
        folder.snippets.append(snippet)
        persistence.addFolder(folder)

        #expect(folder.snippets.count == 1)

        let id = snippet.identifier
        folder.snippets.removeAll { $0.identifier == id }
        persistence.deleteSnippet(snippet)

        #expect(folder.snippets.count == 0)
        #expect(persistence.fetchSnippet(byIdentifier: id) == nil)
    }

    @Test("Snippet toggle enable")
    func toggleEnable() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Folder")
        let snippet = SnippetItem(index: 0, enable: true, title: "Toggle")
        folder.snippets.append(snippet)
        persistence.addFolder(folder)

        #expect(snippet.enable == true)
        snippet.enable = false
        persistence.save()

        let fetched = persistence.fetchSnippet(byIdentifier: snippet.identifier)
        #expect(fetched?.enable == false)
    }

    @Test("Snippet folder relationship")
    func folderRelationship() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Parent")
        let snippet = SnippetItem(index: 0, title: "Child")
        folder.snippets.append(snippet)
        persistence.addFolder(folder)

        let fetched = persistence.fetchSnippet(byIdentifier: snippet.identifier)
        #expect(fetched?.folder?.title == "Parent")
    }
}
