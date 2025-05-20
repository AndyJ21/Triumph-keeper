import Foundation
import CoreData

@objc(KnowledgeByte)
public class KnowledgeByte: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var content: String
    @NSManaged public var languageOrType: String?
    @NSManaged public var tags: String?
    @NSManaged public var dateCreated: Date
    @NSManaged public var lastAccessed: Date?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var displayOrder: Int64
}

extension KnowledgeByte {
    static func fetchRequest() -> NSFetchRequest<KnowledgeByte> {
        return NSFetchRequest<KnowledgeByte>(entityName: "KnowledgeByte")
    }
    
    static func create(in context: NSManagedObjectContext) -> KnowledgeByte {
        let byte = KnowledgeByte(context: context)
        byte.id = UUID()
        byte.dateCreated = Date()
        byte.isFavorite = false
        byte.displayOrder = 0
        return byte
    }
    
    var tagsArray: [String] {
        get {
            return tags?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        }
        set {
            tags = newValue.joined(separator: ", ")
        }
    }
} 