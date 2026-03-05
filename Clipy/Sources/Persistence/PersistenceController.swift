//
//  PersistenceController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import SwiftData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.clipy-app.Clipy", category: "Persistence")

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer
    var mainContext: ModelContext { container.mainContext }

    private init() {
        let schema = Schema([ClipItem.self, SnippetItem.self, FolderItem.self])
        let config = ModelConfiguration("Clipy", schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// For testing with in-memory store
    init(inMemory: Bool) {
        let schema = Schema([ClipItem.self, SnippetItem.self, FolderItem.self])
        let config = ModelConfiguration("ClipyTest", schema: schema, isStoredInMemoryOnly: true)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }

    // MARK: - Clip Operations
    func fetchClips(sortedBy ascending: Bool = false, limit: Int? = nil) -> [ClipItem] {
        var descriptor = FetchDescriptor<ClipItem>(
            sortBy: [SortDescriptor(\.updateTime, order: ascending ? .forward : .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return (try? mainContext.fetch(descriptor)) ?? []
    }

    func fetchClip(byHash hash: String) -> ClipItem? {
        var descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate { $0.dataHash == hash }
        )
        descriptor.fetchLimit = 1
        return try? mainContext.fetch(descriptor).first
    }

    func addClip(_ clip: ClipItem) {
        mainContext.insert(clip)
        try? mainContext.save()
    }

    func deleteClip(_ clip: ClipItem) {
        mainContext.delete(clip)
        try? mainContext.save()
    }

    func deleteAllClips() {
        let clips = fetchClips()
        clips.forEach { mainContext.delete($0) }
        try? mainContext.save()
    }

    func clipCount() -> Int {
        let descriptor = FetchDescriptor<ClipItem>()
        return (try? mainContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Folder Operations
    func fetchFolders(sortedByIndex ascending: Bool = true) -> [FolderItem] {
        let descriptor = FetchDescriptor<FolderItem>(
            sortBy: [SortDescriptor(\.index, order: ascending ? .forward : .reverse)]
        )
        return (try? mainContext.fetch(descriptor)) ?? []
    }

    func fetchFolder(byIdentifier identifier: String) -> FolderItem? {
        var descriptor = FetchDescriptor<FolderItem>(
            predicate: #Predicate { $0.identifier == identifier }
        )
        descriptor.fetchLimit = 1
        return try? mainContext.fetch(descriptor).first
    }

    func addFolder(_ folder: FolderItem) {
        mainContext.insert(folder)
        try? mainContext.save()
    }

    func deleteFolder(_ folder: FolderItem) {
        mainContext.delete(folder)
        try? mainContext.save()
    }

    // MARK: - Snippet Operations
    func fetchSnippet(byIdentifier identifier: String) -> SnippetItem? {
        var descriptor = FetchDescriptor<SnippetItem>(
            predicate: #Predicate { $0.identifier == identifier }
        )
        descriptor.fetchLimit = 1
        return try? mainContext.fetch(descriptor).first
    }

    func addSnippet(_ snippet: SnippetItem) {
        mainContext.insert(snippet)
        try? mainContext.save()
    }

    func deleteSnippet(_ snippet: SnippetItem) {
        mainContext.delete(snippet)
        try? mainContext.save()
    }

    func save() {
        try? mainContext.save()
    }
}
