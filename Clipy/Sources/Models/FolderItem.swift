//
//  FolderItem.swift
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
final class FolderItem {
    @Attribute(.unique) var identifier: String
    var index: Int
    var enable: Bool
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \SnippetItem.folder)
    var snippets: [SnippetItem]

    init(index: Int = 0,
         enable: Bool = true,
         title: String = "",
         identifier: String = UUID().uuidString,
         snippets: [SnippetItem] = []) {
        self.index = index
        self.enable = enable
        self.title = title
        self.identifier = identifier
        self.snippets = snippets
    }

    var sortedSnippets: [SnippetItem] {
        snippets.sorted { $0.index < $1.index }
    }

    var enabledSortedSnippets: [SnippetItem] {
        snippets.filter(\.enable).sorted { $0.index < $1.index }
    }
}
