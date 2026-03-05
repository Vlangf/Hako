//
//  SnippetItem.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import SwiftData

@Model
final class SnippetItem {
    @Attribute(.unique) var identifier: String
    var index: Int
    var enable: Bool
    var title: String
    var content: String
    var folder: FolderItem?

    init(index: Int = 0,
         enable: Bool = true,
         title: String = "",
         content: String = "",
         identifier: String = UUID().uuidString) {
        self.index = index
        self.enable = enable
        self.title = title
        self.content = content
        self.identifier = identifier
    }
}
