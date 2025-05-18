import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TriumphKeeper")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Register the model configuration
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Quick Links
    func createQuickLink(title: String, urlString: String) {
        let context = container.viewContext
        let newLink = QuickLinkItem(context: context)
        newLink.id = UUID()
        newLink.title = title
        newLink.urlString = urlString
        newLink.dateAdded = Date()
        newLink.displayOrder = getNextDisplayOrder(for: "QuickLinkItem")
        
        saveContext()
    }
    
    // MARK: - Triumph Goals
    func createTriumphGoal(name: String) {
        let context = container.viewContext
        let newGoal = TriumphGoal(context: context)
        newGoal.id = UUID()
        newGoal.name = name
        newGoal.dateCreated = Date()
        newGoal.displayOrder = getNextDisplayOrder(for: "TriumphGoal")
        
        saveContext()
    }
    
    // MARK: - Tasks
    func createTask(text: String, dueDate: Date? = nil, for goal: TriumphGoal) {
        let context = container.viewContext
        let newTask = TaskItem(context: context)
        newTask.id = UUID()
        newTask.text = text
        newTask.dueDate = dueDate
        newTask.dateCreated = Date()
        newTask.isCompleted = false
        newTask.belongsToProjectList = goal
        newTask.displayOrder = getNextDisplayOrder(for: "TaskItem", in: goal)
        
        saveContext()
    }
    
    // MARK: - Widget Configuration
    func createWidgetConfiguration(type: String, data: Data? = nil) {
        let context = container.viewContext
        let widget = WidgetConfiguration(context: context)
        widget.id = UUID()
        widget.type = type
        widget.widgetData = data
        widget.displayOrder = getNextDisplayOrder(for: "WidgetConfiguration")
        
        saveContext()
    }
    
    // MARK: - Utility Functions
    private func getNextDisplayOrder(for entityName: String, in goal: TriumphGoal? = nil) -> Int32 {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        if entityName == "TaskItem", let goal = goal {
            fetchRequest.predicate = NSPredicate(format: "belongsToProjectList == %@", goal)
        }
        
        do {
            let results = try container.viewContext.fetch(fetchRequest)
            if let lastItem = results.first as? NSManagedObject,
               let lastOrder = lastItem.value(forKey: "displayOrder") as? Int32 {
                return lastOrder + 1
            }
        } catch {
            print("Error fetching display order: \(error)")
        }
        
        return 0
    }
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
} 