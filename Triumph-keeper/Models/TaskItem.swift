import Foundation
import CoreData

@objc(TaskItem)
public class TaskItem: NSManagedObject, Identifiable {
}

extension TaskItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskItem> {
        return NSFetchRequest<TaskItem>(entityName: "TaskItem")
    }

    @NSManaged public var dateCreated: Date
    @NSManaged public var displayOrder: Int32
    @NSManaged public var dueDate: Date?
    @NSManaged public var id: UUID
    @NSManaged public var isCompleted: Bool
    @NSManaged public var priority: String?
    @NSManaged public var text: String?
    @NSManaged public var belongsToProjectList: TriumphGoal
} 