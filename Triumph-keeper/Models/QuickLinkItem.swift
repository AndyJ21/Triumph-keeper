import Foundation
import CoreData

@objc(QuickLinkItem)
public class QuickLinkItem: NSManagedObject, Identifiable {
    convenience init(context: NSManagedObjectContext, title: String, urlString: String) {
        let entity = NSEntityDescription.entity(forEntityName: "QuickLinkItem", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.title = title
        self.urlString = urlString
        self.dateAdded = Date()
        self.displayOrder = 0
    }
    
    public var identifier: UUID {
        id ?? UUID()
    }
}

extension QuickLinkItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuickLinkItem> {
        return NSFetchRequest<QuickLinkItem>(entityName: "QuickLinkItem")
    }

    @NSManaged public var dateAdded: Date
    @NSManaged public var displayOrder: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var urlString: String?
} 