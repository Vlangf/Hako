import Testing
import Foundation
@testable import Clipy

@Suite("CPYDraggedData Tests")
struct DraggedDataTests {

    @Test("Archive and unarchive folder dragged data")
    func archiveFolderData() throws {
        let identifier = UUID().uuidString
        let draggedData = CPYDraggedData(type: .folder, folderIdentifier: identifier, snippetIdentifier: nil, index: 10)
        let data = try NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: false)

        let unarchived = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CPYDraggedData
        #expect(unarchived != nil)
        #expect(unarchived?.type == draggedData.type)
        #expect(unarchived?.folderIdentifier == identifier)
        #expect(unarchived?.snippetIdentifier == nil)
        #expect(unarchived?.index == 10)
    }

    @Test("Archive and unarchive snippet dragged data")
    func archiveSnippetData() throws {
        let folderID = UUID().uuidString
        let snippetID = UUID().uuidString
        let draggedData = CPYDraggedData(type: .snippet, folderIdentifier: folderID, snippetIdentifier: snippetID, index: 5)
        let data = try NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: false)

        let unarchived = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CPYDraggedData
        #expect(unarchived != nil)
        #expect(unarchived?.type == .snippet)
        #expect(unarchived?.folderIdentifier == folderID)
        #expect(unarchived?.snippetIdentifier == snippetID)
        #expect(unarchived?.index == 5)
    }
}
