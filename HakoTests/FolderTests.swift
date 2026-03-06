import Testing
import Foundation
import SwiftData
@testable import Hako

@Suite("Folder Tests")
@MainActor
struct FolderTests {

    private func makePersistence() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }

    @Test("Create and fetch folder")
    func createFolder() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Test Folder")
        persistence.addFolder(folder)

        let fetched = persistence.fetchFolders()
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Test Folder")
        #expect(fetched.first?.index == 0)
        #expect(fetched.first?.enable == true)
    }

    @Test("Fetch folder by identifier")
    func fetchByIdentifier() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Findable")
        persistence.addFolder(folder)

        let found = persistence.fetchFolder(byIdentifier: folder.identifier)
        #expect(found != nil)
        #expect(found?.title == "Findable")

        let notFound = persistence.fetchFolder(byIdentifier: "nonexistent")
        #expect(notFound == nil)
    }

    @Test("Delete folder cascades to snippets")
    func deleteFolderCascade() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "To Delete")
        let snippet = SnippetItem(index: 0, title: "Child Snippet", content: "content")
        folder.snippets.append(snippet)
        persistence.addFolder(folder)

        #expect(persistence.fetchFolders().count == 1)
        #expect(persistence.fetchSnippet(byIdentifier: snippet.identifier) != nil)

        persistence.deleteFolder(folder)

        #expect(persistence.fetchFolders().count == 0)
    }

    @Test("Folder sorting by index")
    func folderSortOrder() {
        let persistence = makePersistence()
        persistence.addFolder(FolderItem(index: 2, title: "C"))
        persistence.addFolder(FolderItem(index: 0, title: "A"))
        persistence.addFolder(FolderItem(index: 1, title: "B"))

        let ascending = persistence.fetchFolders(sortedByIndex: true)
        #expect(ascending.map(\.title) == ["A", "B", "C"])
    }

    @Test("Add snippets to folder")
    func addSnippets() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Folder")
        let s1 = SnippetItem(index: 0, title: "First")
        let s2 = SnippetItem(index: 1, title: "Second")
        folder.snippets.append(s1)
        folder.snippets.append(s2)
        persistence.addFolder(folder)

        let fetched = persistence.fetchFolders().first
        #expect(fetched?.snippets.count == 2)
        #expect(fetched?.sortedSnippets.first?.title == "First")
        #expect(fetched?.sortedSnippets.last?.title == "Second")
    }

    @Test("Enabled sorted snippets filters disabled")
    func enabledSortedSnippets() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Folder")
        let s1 = SnippetItem(index: 0, enable: true, title: "Enabled")
        let s2 = SnippetItem(index: 1, enable: false, title: "Disabled")
        let s3 = SnippetItem(index: 2, enable: true, title: "Also Enabled")
        folder.snippets.append(contentsOf: [s1, s2, s3])
        persistence.addFolder(folder)

        let fetched = persistence.fetchFolders().first
        #expect(fetched?.enabledSortedSnippets.count == 2)
        #expect(fetched?.enabledSortedSnippets.map(\.title) == ["Enabled", "Also Enabled"])
    }

    @Test("Update folder properties")
    func updateFolder() {
        let persistence = makePersistence()
        let folder = FolderItem(index: 0, title: "Original")
        persistence.addFolder(folder)

        folder.title = "Updated"
        folder.enable = false
        folder.index = 5
        persistence.save()

        let fetched = persistence.fetchFolders().first
        #expect(fetched?.title == "Updated")
        #expect(fetched?.enable == false)
        #expect(fetched?.index == 5)
    }
}
