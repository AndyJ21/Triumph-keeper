import Foundation
import CoreData

@objc(WidgetConfiguration)
public class WidgetConfiguration: NSManagedObject, Identifiable {
    convenience init(context: NSManagedObjectContext, type: String) {
        let entity = NSEntityDescription.entity(forEntityName: "WidgetConfiguration", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.type = type
        self.displayOrder = 0
    }
}

extension WidgetConfiguration {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WidgetConfiguration> {
        return NSFetchRequest<WidgetConfiguration>(entityName: "WidgetConfiguration")
    }

    @NSManaged public var displayOrder: Int32
    @NSManaged public var id: UUID
    @NSManaged public var type: String?
    @NSManaged public var widgetData: Data?
} 