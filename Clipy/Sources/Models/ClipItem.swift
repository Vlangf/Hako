//
//  ClipItem.swift
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
final class ClipItem {
    @Attribute(.unique) var dataHash: String
    var dataPath: String
    var title: String
    var primaryType: String
    var updateTime: Int
    var thumbnailPath: String
    var isColorCode: Bool

    init(dataPath: String = "",
         title: String = "",
         dataHash: String = "",
         primaryType: String = "",
         updateTime: Int = 0,
         thumbnailPath: String = "",
         isColorCode: Bool = false) {
        self.dataPath = dataPath
        self.title = title
        self.dataHash = dataHash
        self.primaryType = primaryType
        self.updateTime = updateTime
        self.thumbnailPath = thumbnailPath
        self.isColorCode = isColorCode
    }
}
