//
//  ClipService.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/11/17.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Cocoa
import SwiftData
import Combine

final class ClipService {

    // MARK: - Properties
    fileprivate var cachedChangeCount: Int = 0
    fileprivate var storeTypes = [String: NSNumber]()
    fileprivate let lock = NSRecursiveLock(name: "com.hako-app.Hako.ClipUpdatable")
    fileprivate var cancellables = Set<AnyCancellable>()

    // MARK: - Clips
    func startMonitoring() {
        cancellables.removeAll()
        // Pasteboard observe timer
        Timer.publish(every: 0.75, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .map { _ in NSPasteboard.general.changeCount }
            .filter { [weak self] changeCount in
                guard let self = self else { return false }
                return changeCount != self.cachedChangeCount
            }
            .sink { [weak self] changeCount in
                self?.cachedChangeCount = changeCount
                self?.create()
            }
            .store(in: &cancellables)
        // Store types
        UserDefaults.standard.publisher(for: \.kCPYPrefStoreTypesKey)
            .compactMap { $0 as? [String: NSNumber] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.storeTypes = $0
            }
            .store(in: &cancellables)
    }

    @MainActor
    func clearAll() {
        let persistence = PersistenceController.shared
        let clips = persistence.fetchClips()

        // Delete saved images
        clips
            .filter { !$0.thumbnailPath.isEmpty }
            .map { $0.thumbnailPath }
            .forEach { ImageCache.shared.removeObject(forKey: $0) }
        // Delete SwiftData
        persistence.deleteAllClips()
        // Delete writed datas
        AppState.shared.dataCleanService.cleanDatas()
    }

    @MainActor
    func delete(with clip: ClipItem) {
        // Delete saved images
        let path = clip.thumbnailPath
        if !path.isEmpty {
            ImageCache.shared.removeObject(forKey: path)
        }
        // Delete SwiftData
        PersistenceController.shared.deleteClip(clip)
    }

    func incrementChangeCount() {
        cachedChangeCount += 1
    }

}

// MARK: - Create Clip
extension ClipService {
    fileprivate func create() {
        lock.lock(); defer { lock.unlock() }

        // Store types
        if !storeTypes.values.contains(NSNumber(value: true)) { return }
        // Pasteboard types
        let pasteboard = NSPasteboard.general
        let types = self.types(with: pasteboard)
        if types.isEmpty { return }

        // Excluded application
        guard !AppState.shared.excludeAppService.frontProcessIsExcludedApplication() else { return }
        // Special applications
        guard !AppState.shared.excludeAppService.copiedProcessIsExcludedApplications(pasteboard: pasteboard) else { return }

        // Create data
        let data = ClipData(pasteboard: pasteboard, types: types)
        save(with: data)
    }

    func create(with image: NSImage) {
        lock.lock(); defer { lock.unlock() }

        // Create only image data
        let data = ClipData(image: image)
        save(with: data)
    }

    fileprivate func save(with data: ClipData) {
        // Don't save empty string history
        if data.isOnlyStringType && data.stringValue.isEmpty { return }

        // Overwrite same history
        let defaults = AppState.shared.defaults
        let isOverwriteHistory = defaults.bool(forKey: Constants.UserDefaults.overwriteSameHistory)
        let isCopySameHistory = defaults.bool(forKey: Constants.UserDefaults.copySameHistory)
        let savedHash = (isOverwriteHistory) ? data.hash : Int(arc4random() % 1000000)

        // Saved time and path
        let unixTime = Int(Date().timeIntervalSince1970)
        let savedPath = Utilities.applicationSupportFolder() + "/\(NSUUID().uuidString).data"

        DispatchQueue.main.async {
            let persistence = PersistenceController.shared

            // Copy already copied history
            if persistence.fetchClip(byHash: "\(data.hash)") != nil, !isCopySameHistory { return }

            // Create ClipItem
            let clip = ClipItem(
                dataPath: savedPath,
                title: data.stringValue[0...10000],
                dataHash: "\(savedHash)",
                primaryType: data.primaryType?.rawValue ?? "",
                updateTime: unixTime
            )

            // Save thumbnail image
            if let thumbnailImage = data.thumbnailImage {
                ImageCache.shared.setObject(thumbnailImage, forKey: "\(unixTime)")
                clip.thumbnailPath = "\(unixTime)"
            }
            if let colorCodeImage = data.colorCodeImage {
                ImageCache.shared.setObject(colorCodeImage, forKey: "\(unixTime)")
                clip.thumbnailPath = "\(unixTime)"
                clip.isColorCode = true
            }
            // Save .data file and SwiftData
            if Utilities.prepareSaveToPath(Utilities.applicationSupportFolder()) {
                if let archived = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false) {
                    do {
                        try archived.write(to: URL(fileURLWithPath: savedPath))
                        persistence.addClip(clip)
                    } catch {}
                }
            }
        }
    }

    private func types(with pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        let types = pasteboard.types?.filter { canSave(with: $0) } ?? []
        return NSOrderedSet(array: types).array as? [NSPasteboard.PasteboardType] ?? []
    }

    private func canSave(with type: NSPasteboard.PasteboardType) -> Bool {
        let dictionary = ClipData.availableTypesDictinary
        guard let value = dictionary[type] else { return false }
        guard let number = storeTypes[value] else { return false }
        return number.boolValue
    }
}

// MARK: - KVO key for UserDefaults
private extension UserDefaults {
    @objc var kCPYPrefStoreTypesKey: Any? {
        return object(forKey: "kCPYPrefStoreTypesKey")
    }
}
