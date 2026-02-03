import Foundation
import CoreData

extension FileItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileItem> {
        return NSFetchRequest<FileItem>(entityName: "FileItem")
    }

    @NSManaged public var accessedAt: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var fileSize: Int64
    @NSManaged public var hasUncommittedChanges: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var isDirectory: Bool
    @NSManaged public var isGitRepo: Bool
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var path: String?
    @NSManaged public var priority: Int16
    @NSManaged public var directory: TrackedDirectory?
    @NSManaged public var tags: NSSet?
}

// MARK: Generated accessors for tags
extension FileItem {
    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
}

extension FileItem: Identifiable {
}
