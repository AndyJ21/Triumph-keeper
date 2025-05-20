import Foundation
import CoreData

@objc(TriumphGoal)
public class TriumphGoal: NSManagedObject, Identifiable {
}

extension TriumphGoal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TriumphGoal> {
        return NSFetchRequest<TriumphGoal>(entityName: "TriumphGoal")
    }

    @NSManaged public var dateCreated: Date
    @NSManaged public var goalDescription: String?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var tasks: NSSet?
}

extension TriumphGoal {
    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: TaskItem)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: TaskItem)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)
} 