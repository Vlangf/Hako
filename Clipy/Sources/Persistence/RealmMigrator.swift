//
//  RealmMigrator.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import SwiftData
import RealmSwift
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.clipy-app.Clipy", category: "RealmMigrator")

/// One-time migration from Realm to SwiftData
/// Called on first launch after update
@MainActor
enum RealmMigrator {

    private static let migrationCompletedKey = "kClipyRealmToSwiftDataMigrationCompleted"

    static func migrateIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationCompletedKey) else { return }

        // Check for Realm files
        let realmPaths = possibleRealmPaths()
        guard let realmPath = realmPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            // No Realm files found — fresh install, nothing to migrate
            defaults.set(true, forKey: migrationCompletedKey)
            return
        }

        logger.info("Starting Realm to SwiftData migration from: \(realmPath, privacy: .public)")

        do {
            try migrateRealmData(from: realmPath, to: context)
            archiveRealmFiles(realmPaths)
            defaults.set(true, forKey: migrationCompletedKey)
            logger.info("Realm to SwiftData migration completed successfully")
        } catch {
            logger.error("Realm to SwiftData migration failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private

    private static func possibleRealmPaths() -> [String] {
        let defaultPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            .first.map { ($0 as NSString).appendingPathComponent("default.realm") } ?? ""
        let applicationSupportPath = CPYUtilities.applicationSupportFolder()
        let appSupportRealm = (applicationSupportPath as NSString).appendingPathComponent("default.realm")
        // Realm default location
        let homeRealm = (NSHomeDirectory() as NSString).appendingPathComponent("default.realm")

        return [defaultPath, appSupportRealm, homeRealm].filter { !$0.isEmpty }
    }

    private static func migrateRealmData(from realmPath: String, to context: ModelContext) throws {
        let realmURL = URL(fileURLWithPath: realmPath)
        let config = Realm.Configuration(
            fileURL: realmURL,
            readOnly: true,
            deleteRealmIfMigrationNeeded: false,
            objectTypes: []
        )

        let realm: Realm
        do {
            realm = try Realm(configuration: config)
        } catch {
            // If schema mismatch, try with migration block that accepts any version
            let fallbackConfig = Realm.Configuration(
                fileURL: realmURL,
                schemaVersion: 100,
                migrationBlock: { _, _ in },
                objectTypes: []
            )
            realm = try Realm(configuration: fallbackConfig)
        }

        // Migrate CPYClip → ClipItem
        let clips = realm.dynamicObjects("CPYClip")
        var clipCount = 0
        for clip in clips {
            let item = ClipItem(
                dataPath: clip["dataPath"] as? String ?? "",
                title: clip["title"] as? String ?? "",
                dataHash: clip["dataHash"] as? String ?? "",
                primaryType: clip["primaryType"] as? String ?? "",
                updateTime: clip["updateTime"] as? Int ?? 0,
                thumbnailPath: clip["thumbnailPath"] as? String ?? "",
                isColorCode: clip["isColorCode"] as? Bool ?? false
            )
            context.insert(item)
            clipCount += 1
        }
        logger.info("Migrated \(clipCount) clips")

        // Migrate CPYFolder → FolderItem (with nested CPYSnippet → SnippetItem)
        let folders = realm.dynamicObjects("CPYFolder")
        var folderCount = 0
        var snippetCount = 0
        for folder in folders {
            let folderItem = FolderItem(
                index: folder["index"] as? Int ?? 0,
                enable: folder["enable"] as? Bool ?? true,
                title: folder["title"] as? String ?? "",
                identifier: folder["identifier"] as? String ?? UUID().uuidString
            )

            // Migrate snippets within this folder
            let snippetsList = folder.dynamicList("snippets")
            for snippet in snippetsList {
                let snippetItem = SnippetItem(
                    index: snippet["index"] as? Int ?? 0,
                    enable: snippet["enable"] as? Bool ?? true,
                    title: snippet["title"] as? String ?? "",
                    content: snippet["content"] as? String ?? "",
                    identifier: snippet["identifier"] as? String ?? UUID().uuidString
                )
                snippetItem.folder = folderItem
                context.insert(snippetItem)
                snippetCount += 1
            }

            context.insert(folderItem)
            folderCount += 1
        }
        logger.info("Migrated \(folderCount) folders with \(snippetCount) snippets")

        try context.save()
    }

    private static func archiveRealmFiles(_ paths: [String]) {
        let fileManager = FileManager.default
        for path in paths {
            guard fileManager.fileExists(atPath: path) else { continue }
            let backupDir = (path as NSString).deletingLastPathComponent
            let backupPath = (backupDir as NSString).appendingPathComponent("default.realm.backup")

            // Create backup directory
            try? fileManager.createDirectory(atPath: backupPath, withIntermediateDirectories: true)

            // Move realm and associated files into backup dir
            let baseName = (path as NSString).lastPathComponent
            try? fileManager.moveItem(atPath: path, toPath: (backupPath as NSString).appendingPathComponent(baseName))

            // Also archive .lock and .management files
            for suffix in [".lock", ".management", ".note"] {
                let auxPath = path + suffix
                if fileManager.fileExists(atPath: auxPath) {
                    try? fileManager.moveItem(
                        atPath: auxPath,
                        toPath: (backupPath as NSString).appendingPathComponent(baseName + suffix)
                    )
                }
            }
        }
    }
}
