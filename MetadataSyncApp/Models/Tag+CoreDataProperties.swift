import Foundation
import CoreData

extension Tag {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var color: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var items: NSSet?
}

// MARK: Generated accessors for items
extension Tag {
    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: FileItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: FileItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
}

extension Tag: Identifiable {
}
