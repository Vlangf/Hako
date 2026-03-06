//
//  DataCleanService.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/11/20.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Combine
import SwiftData

final class DataCleanService {

    // MARK: - Properties
    fileprivate var cancellables = Set<AnyCancellable>()

    // MARK: - Monitoring
    func startMonitoring() {
        cancellables.removeAll()
        // Clean datas every 30 minutes
        Timer.publish(every: 60 * 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.cleanDatas() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Delete Data
    @MainActor
    func cleanDatas() {
        let persistence = PersistenceController.shared
        let maxHistorySize = AppState.shared.defaults.integer(forKey: Constants.UserDefaults.maxHistorySize)
        let allClips = persistence.fetchClips(sortedBy: false) // newest first

        if allClips.count > maxHistorySize {
            let clipsToRemove = Array(allClips.dropFirst(maxHistorySize))
            clipsToRemove
                .filter { !$0.thumbnailPath.isEmpty }
                .forEach { ImageCache.shared.removeObject(forKey: $0.thumbnailPath) }
            clipsToRemove.forEach { persistence.deleteClip($0) }
        }

        cleanFiles()
    }

    @MainActor
    private func cleanFiles() {
        let fileManager = FileManager.default
        guard let paths = try? fileManager.contentsOfDirectory(atPath: Utilities.applicationSupportFolder()) else { return }

        let persistence = PersistenceController.shared
        let allClipPaths = Set(persistence.fetchClips().compactMap { $0.dataPath.components(separatedBy: "/").last })

        // Delete diff datas
        Set(paths).subtracting(allClipPaths)
            .map { Utilities.applicationSupportFolder() + "/" + $0 }
            .forEach { Utilities.deleteData(at: $0) }
    }
}
