//
//  ImageCache.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa

final class ImageCache {

    // MARK: - Singleton
    static let shared = ImageCache()

    // MARK: - Properties
    private let memoryCache = NSCache<NSString, NSImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: String

    // MARK: - Initialize
    private init() {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        cacheDirectory = ((paths.first ?? NSTemporaryDirectory()) as NSString)
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.clipy-app.Clipy")
        cacheDirectory.withCString { _ in
            try? fileManager.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Public
    func setObject(_ image: NSImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        // Write to disk
        if let data = image.tiffRepresentation {
            let path = filePath(forKey: key)
            fileManager.createFile(atPath: path, contents: data)
        }
    }

    func object(forKey key: String) -> NSImage? {
        // Check memory cache
        if let image = memoryCache.object(forKey: key as NSString) {
            return image
        }
        // Check disk cache
        let path = filePath(forKey: key)
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        memoryCache.setObject(image, forKey: key as NSString)
        return image
    }

    func object(forKey key: String, block: @escaping (String, NSImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let image = self?.object(forKey: key)
            block(key, image)
        }
    }

    func removeObject(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        let path = filePath(forKey: key)
        try? fileManager.removeItem(atPath: path)
    }

    func removeAllObjects() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(atPath: cacheDirectory)
        try? fileManager.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Private
    private func filePath(forKey key: String) -> String {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return (cacheDirectory as NSString).appendingPathComponent(safeKey)
    }
}
