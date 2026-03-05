//
//  ScreenshotObserver.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa
import Combine

final class ScreenshotObserver {

    // MARK: - Properties
    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startObserving()
            } else {
                stopObserving()
            }
        }
    }

    let addedImagePublisher = PassthroughSubject<NSImage, Never>()

    private var query: NSMetadataQuery?
    private var previousResults = Set<String>()

    // MARK: - Observe
    private func startObserving() {
        stopObserving()
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryLocalComputerScope]
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture == 1")
        query.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSCreationDateKey, ascending: false)]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )

        query.start()
        self.query = query

        // Populate initial results to avoid importing old screenshots
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.populateInitialResults()
        }
    }

    private func stopObserving() {
        query?.stop()
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: query)
        query = nil
        previousResults.removeAll()
    }

    private func populateInitialResults() {
        guard let query = query else { return }
        query.disableUpdates()
        for i in 0..<query.resultCount {
            if let item = query.result(at: i) as? NSMetadataItem,
               let path = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                previousResults.insert(path)
            }
        }
        query.enableUpdates()
    }

    @objc private func queryDidUpdate(_ notification: Notification) {
        guard let query = query else { return }
        query.disableUpdates()
        defer { query.enableUpdates() }

        for i in 0..<query.resultCount {
            guard let item = query.result(at: i) as? NSMetadataItem,
                  let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { continue }

            if !previousResults.contains(path) {
                previousResults.insert(path)
                if let image = NSImage(contentsOfFile: path) {
                    addedImagePublisher.send(image)
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
