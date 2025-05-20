import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create sample knowledge bytes
        let context = controller.container.viewContext
        
        let sampleBytes = [
            (title: "SwiftUI View Modifier", content: "extension View {\n    func cardStyle() -> some View {\n        self\n            .padding()\n            .background(Color(.systemBackground))\n            .cornerRadius(12)\n            .shadow(radius: 2)\n    }\n}", language: "Swift", tags: "swift,swiftui,modifier"),
            (title: "Git Command", content: "git log --oneline --graph --all", language: "Git", tags: "git,command,log"),
            (title: "Docker Compose", content: "version: '3'\nservices:\n  app:\n    build: .\n    ports:\n      - \"8080:8080\"", language: "YAML", tags: "docker,compose,config")
        ]
        
        for (index, byte) in sampleBytes.enumerated() {
            let knowledgeByte = KnowledgeByte(context: context)
            knowledgeByte.id = UUID()
            knowledgeByte.title = byte.title
            knowledgeByte.content = byte.content
            knowledgeByte.languageOrType = byte.language
            knowledgeByte.tags = byte.tags
            knowledgeByte.dateCreated = Date()
            knowledgeByte.isFavorite = index == 0
            knowledgeByte.displayOrder = Int64(index)
        }
        
        try? context.save()
        return controller
    }()

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
    
    func deleteQuickLink(_ link: QuickLinkItem) {
        let context = container.viewContext
        context.delete(link)
        saveContext()
    }
    
    // MARK: - Triumph Goals
    func createTriumphGoal(name: String) -> TriumphGoal {
        let context = container.viewContext
        let newGoal = TriumphGoal(context: context)
        newGoal.id = UUID()
        newGoal.name = name
        newGoal.dateCreated = Date()
        newGoal.displayOrder = getNextDisplayOrder(for: "TriumphGoal")
        
        saveContext()
        return newGoal
    }
    
    // MARK: - Tasks
    func createTask(text: String, dueDate: Date? = nil, priority: String = "Medium", for goal: TriumphGoal) -> TaskItem {
        let context = container.viewContext
        let newTask = TaskItem(context: context)
        newTask.id = UUID()
        newTask.text = text
        newTask.dueDate = dueDate
        newTask.dateCreated = Date()
        newTask.isCompleted = false
        newTask.priority = priority
        newTask.belongsToProjectList = goal
        newTask.displayOrder = getNextDisplayOrder(for: "TaskItem", in: goal)
        
        saveContext()
        return newTask
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
    
    // MARK: - Knowledge Bytes
    func createKnowledgeByte(title: String?, content: String, languageOrType: String? = nil, tags: String? = nil) -> KnowledgeByte {
        let context = container.viewContext
        let byte = KnowledgeByte(context: context)
        byte.id = UUID()
        byte.title = title
        byte.content = content
        byte.languageOrType = languageOrType
        byte.tags = tags
        byte.dateCreated = Date()
        byte.isFavorite = false
        byte.displayOrder = Int64(getNextDisplayOrder(for: "KnowledgeByte"))
        
        saveContext()
        return byte
    }
    
    func deleteKnowledgeByte(_ byte: KnowledgeByte) {
        let context = container.viewContext
        context.delete(byte)
        saveContext()
    }
    
    func updateKnowledgeByte(_ byte: KnowledgeByte) {
        byte.lastAccessed = Date()
        saveContext()
    }
    
    func toggleFavorite(_ byte: KnowledgeByte) {
        byte.isFavorite.toggle()
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
    
    // Add this function to the PersistenceController class
    func fetchWidgetConfigurations(ofType type: String) -> [WidgetConfiguration] {
        let request: NSFetchRequest<WidgetConfiguration> = WidgetConfiguration.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", type)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WidgetConfiguration.displayOrder, ascending: true)]
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching widget configurations: \(error)")
            return []
        }
    }
} 