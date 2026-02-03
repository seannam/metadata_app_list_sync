import Foundation
import CoreData

extension TrackedDirectory {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackedDirectory> {
        return NSFetchRequest<TrackedDirectory>(entityName: "TrackedDirectory")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var lastScannedAt: Date?
    @NSManaged public var name: String?
    @NSManaged public var path: String?
    @NSManaged public var items: NSSet?
}

// MARK: Generated accessors for items
extension TrackedDirectory {
    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: FileItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: FileItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
}

extension TrackedDirectory: Identifiable {
}
