//
//  XTTImageStore.swift
//  WorkspaceOrganizer
//
//  Saves and loads user photos in the app's Documents/Images directory.
//  Fully offline — files never leave the device.
//

import UIKit

enum XTTImageStore {

    private static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Images", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Persist an image, returning the generated relative filename.
    static func save(_ image: UIImage) -> String? {
        let fileName = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    /// Load a previously stored image by relative filename.
    static func load(_ fileName: String?) -> UIImage? {
        guard let fileName = fileName else { return nil }
        let url = directory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Remove a stored image by relative filename.
    static func delete(_ fileName: String?) {
        guard let fileName = fileName else { return }
        let url = directory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
