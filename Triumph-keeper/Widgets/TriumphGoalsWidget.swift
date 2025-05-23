import SwiftUI
import CoreData

struct TriumphGoalsWidget: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TriumphGoal.displayOrder, ascending: true)],
        animation: .default)
    private var goals: FetchedResults<TriumphGoal>
    
    @State private var isAddingGoal = false
    @State private var selectedGoal: TriumphGoal?
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Triumph Goals", systemImage: "flag.fill")
                    .font(.headline)
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                    Button(action: { isAddingGoal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.bottom, 4)
            
            if goals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "flag.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.7))
                    Text("No goals yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: { isAddingGoal = true }) {
                        Text("Add Goal")
                            .font(.footnote.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(goals, id: \.objectID) { goal in
                            GoalRow(goal: goal, isSelected: selectedGoal?.objectID == goal.objectID)
                                .onTapGesture {
                                    withAnimation {
                                        selectedGoal = goal
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
        .sheet(isPresented: $isAddingGoal) {
            AddGoalView(isPresented: $isAddingGoal)
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailView(goal: goal)
        }
        .alert("Delete All Goals", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllGoals()
            }
        } message: {
            Text("Are you sure you want to delete all goals? This will also delete all associated tasks.")
        }
    }
    
    private func deleteAllGoals() {
        withAnimation {
            viewContext.performAndWait {
                // Delete all goals and their associated tasks
                for goal in goals {
                    // First delete all associated tasks
                    if let tasks = goal.tasks?.allObjects as? [TaskItem] {
                        for task in tasks {
                            viewContext.delete(task)
                        }
                    }
                    // Then delete the goal
                    viewContext.delete(goal)
                }
                try? viewContext.save()
            }
        }
    }
}

struct GoalRow: View {
    @ObservedObject var goal: TriumphGoal
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    var completedTasks: Int {
        (goal.tasks?.allObjects as? [TaskItem])?.filter { $0.isCompleted }.count ?? 0
    }
    
    var totalTasks: Int {
        goal.tasks?.count ?? 0
    }
    
    var progressValue: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name ?? "")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            if totalTasks > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progressValue)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    HStack {
                        Text("\(completedTasks)/\(totalTasks) completed")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progressValue * 100))%")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }
            } else {
                Text("No tasks yet")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .contextMenu {
            Button(action: {
                showEditSheet = true
            }) {
                Label("Edit Goal", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete Goal", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditGoalView(goal: goal, isPresented: $showEditSheet)
        }
        .alert("Delete Goal", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteGoal()
            }
        } message: {
            Text("Are you sure you want to delete this goal? This will also delete all associated tasks.")
        }
    }
    
    private func deleteGoal() {
        withAnimation {
            viewContext.performAndWait {
                // First delete all associated tasks
                if let tasks = goal.tasks?.allObjects as? [TaskItem] {
                    for task in tasks {
                        viewContext.delete(task)
                    }
                }
                // Then delete the goal
                viewContext.delete(goal)
                try? viewContext.save()
            }
        }
    }
}

struct EditGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var goal: TriumphGoal
    @Binding var isPresented: Bool
    
    @State private var name: String
    @State private var description: String
    @State private var hasDescription: Bool
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(goal: TriumphGoal, isPresented: Binding<Bool>) {
        self.goal = goal
        self._isPresented = isPresented
        self._name = State(initialValue: goal.name ?? "")
        self._description = State(initialValue: goal.goalDescription ?? "")
        self._hasDescription = State(initialValue: goal.goalDescription != nil && !goal.goalDescription!.isEmpty)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f0f2f5"),
                        colorScheme == .dark ? Color(hex: "2d2d2d") : Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon and Title
                        VStack(spacing: 16) {
                            Image(systemName: "flag.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Edit Goal")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                        }
                        .padding(.top, 20)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Goal Name")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter goal name", text: $name)
                                    .font(.system(.body, design: .rounded))
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                           radius: 4, x: 0, y: 2)
                            }
                            
                            // Description Toggle
                            Toggle(isOn: $hasDescription) {
                                Label("Add Description", systemImage: "text.alignleft")
                                    .font(.system(.body, design: .rounded))
                            }
                            
                            // Description Field
                            if hasDescription {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.secondary)
                                    
                                    TextEditor(text: $description)
                                        .font(.system(.body, design: .rounded))
                                        .frame(minHeight: 100)
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                               radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateGoal()
                    }
                    .font(.system(.body, design: .rounded).bold())
                    .disabled(name.isEmpty)
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func updateGoal() {
        withAnimation {
            viewContext.performAndWait {
                do {
                    goal.name = name
                    if hasDescription {
                        goal.goalDescription = description
                    } else {
                        goal.goalDescription = nil
                    }
                    
                    try viewContext.save()
                    isPresented = false
                } catch {
                    errorMessage = "Failed to save changes: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

struct GoalDetailView: View {
    let goal: TriumphGoal
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAddingTask = false
    @State private var showDeleteConfirmation = false
    @State private var taskToDelete: TaskItem?
    
    @FetchRequest private var tasks: FetchedResults<TaskItem>
    
    init(goal: TriumphGoal) {
        self.goal = goal
        _tasks = FetchRequest<TaskItem>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \TaskItem.displayOrder, ascending: true),
                NSSortDescriptor(keyPath: \TaskItem.dateCreated, ascending: true)
            ],
            predicate: NSPredicate(format: "belongsToProjectList == %@", goal)
        )
    }
    
    var completedTasks: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var totalTasks: Int {
        tasks.count
    }
    
    var progressValue: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var descriptionCard: some View {
        Group {
            if let goalDescription = goal.goalDescription, !goalDescription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(goalDescription)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.1),
                               radius: 8, x: 0, y: 4)
                )
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f0f2f5"),
                        colorScheme == .dark ? Color(hex: "2d2d2d") : Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Description Card
                        descriptionCard
                        
                        // Progress Card
                        VStack(spacing: 12) {
                            HStack {
                                Text("Progress")
                                    .font(.system(.headline, design: .rounded))
                                Spacer()
                                Text("\(completedTasks)/\(totalTasks)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: progressValue)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            
                            Text("\(Int(progressValue * 100))% Complete")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                       radius: 8, x: 0, y: 4)
                        )
                        
                        if tasks.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue.opacity(0.7))
                                Text("No tasks yet")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.medium)
                                Text("Add your first task to start tracking your progress")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button(action: { isAddingTask = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Task")
                                    }
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                           radius: 8, x: 0, y: 4)
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(tasks, id: \.objectID) { task in
                                    TaskRow(task: task) {
                                        taskToDelete = task
                                        showDeleteConfirmation = true
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(goal.name ?? "")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingTask = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Task")
                        }
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                }
            }
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(goal: goal, isPresented: $isAddingTask) { _ in }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Task"),
                    message: Text("Are you sure you want to delete this task?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let task = taskToDelete {
                            deleteTask(task)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        withAnimation {
            viewContext.performAndWait {
                viewContext.delete(task)
                try? viewContext.save()
            }
        }
    }
}

struct TaskRow: View {
    @ObservedObject var task: TaskItem
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    let onDelete: () -> Void
    
    private var priorityColor: Color {
        switch task.priority ?? "Medium" {
        case "High": return .red
        case "Low": return .green
        default: return .blue
        }
    }
    
    private var priorityIcon: String {
        switch task.priority ?? "Medium" {
        case "High": return "exclamationmark.circle.fill"
        case "Low": return "arrow.down.circle.fill"
        default: return "equal.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleCompletion) {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if task.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(task.text ?? "")
                        .font(.system(.body, design: .rounded))
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    Image(systemName: priorityIcon)
                        .foregroundColor(priorityColor)
                        .font(.system(size: 14))
                }
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dueDate, style: .date)
                            .font(.system(.caption, design: .rounded))
                        
                        if dueDate < Date() && !task.isCompleted {
                            Text("Overdue")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                       radius: 4, x: 0, y: 2)
        )
        .id(task.objectID)
    }
    
    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewContext.performAndWait {
                task.isCompleted.toggle()
                try? viewContext.save()
            }
        }
    }
}

struct AddTaskView: View {
    let goal: TriumphGoal?
    @Binding var isPresented: Bool
    var onTaskCreated: ((TaskItem) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var text = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var showCalendar = false
    @State private var priority: TaskPriority = .medium
    
    enum TaskPriority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .blue
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "arrow.down.circle.fill"
            case .medium: return "equal.circle.fill"
            case .high: return "exclamationmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f0f2f5"),
                        colorScheme == .dark ? Color(hex: "2d2d2d") : Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon and Title
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Add New Task")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                        }
                        .padding(.top, 20)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Task Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Task Description")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter task description", text: $text)
                                    .font(.system(.body, design: .rounded))
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                           radius: 4, x: 0, y: 2)
                            }
                            
                            // Priority Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Priority")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                                        Button(action: { self.priority = priority }) {
                                            HStack {
                                                Image(systemName: priority.icon)
                                                Text(priority.rawValue)
                                            }
                                            .font(.system(.subheadline, design: .rounded))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(self.priority == priority ? 
                                                          priority.color.opacity(0.2) : 
                                                          Color(.systemBackground))
                                            )
                                            .foregroundColor(self.priority == priority ? 
                                                           priority.color : 
                                                           .secondary)
                                        }
                                    }
                                }
                            }
                            
                            // Due Date Toggle
                            Toggle(isOn: $hasDueDate) {
                                Label("Set Due Date", systemImage: "calendar")
                                    .font(.system(.body, design: .rounded))
                            }
                            
                            // Due Date Picker
                            if hasDueDate {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Due Date")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        showCalendar.toggle()
                                    }) {
                                        HStack {
                                            Image(systemName: "calendar")
                                            Text(dueDate, style: .date)
                                                .font(.system(.body, design: .rounded))
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                               radius: 4, x: 0, y: 2)
                                    }
                                    
                                    if showCalendar {
                                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                                            .datePickerStyle(GraphicalDatePickerStyle())
                                            .padding()
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                                   radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTask()
                        isPresented = false
                    }
                    .font(.system(.body, design: .rounded).bold())
                    .disabled(text.isEmpty)
                }
            }
        }
    }
    
    private func addTask() {
        let task = TaskItem(context: viewContext)
        task.id = UUID()
        task.text = text
        task.isCompleted = false
        task.dateCreated = Date()
        task.priority = priority.rawValue
        task.displayOrder = 0
        
        if hasDueDate {
            task.dueDate = dueDate
        }
        
        if let goal = goal {
            task.belongsToProjectList = goal
        }
        
        try? viewContext.save()
        onTaskCreated?(task)
    }
}

struct AddGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var description = ""
    @State private var hasDescription = false
    @State private var tasks: [TaskItem] = []
    @State private var isAddingTask = false
    @State private var showDeleteConfirmation = false
    @State private var taskToDelete: TaskItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f0f2f5"),
                        colorScheme == .dark ? Color(hex: "2d2d2d") : Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon and Title
                        VStack(spacing: 16) {
                            Image(systemName: "flag.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Create New Goal")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                        }
                        .padding(.top, 20)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Goal Name")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter goal name", text: $name)
                                    .font(.system(.body, design: .rounded))
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                           radius: 4, x: 0, y: 2)
                            }
                            
                            // Description Toggle
                            Toggle(isOn: $hasDescription) {
                                Label("Add Description", systemImage: "text.alignleft")
                                    .font(.system(.body, design: .rounded))
                            }
                            
                            // Description Field
                            if hasDescription {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.secondary)
                                    
                                    TextEditor(text: $description)
                                        .font(.system(.body, design: .rounded))
                                        .frame(minHeight: 100)
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                               radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            // Tasks Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Tasks")
                                        .font(.system(.headline, design: .rounded))
                                    Spacer()
                                    Button(action: { isAddingTask = true }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Task")
                                        }
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                if tasks.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.blue.opacity(0.7))
                                        Text("No tasks yet")
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                                   radius: 4, x: 0, y: 2)
                                    )
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(tasks, id: \.objectID) { task in
                                            TaskRow(task: task) {
                                                taskToDelete = task
                                                showDeleteConfirmation = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        addGoal()
                        isPresented = false
                    }
                    .font(.system(.body, design: .rounded).bold())
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(goal: nil, isPresented: $isAddingTask) { task in
                    tasks.append(task)
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Task"),
                    message: Text("Are you sure you want to delete this task?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let task = taskToDelete {
                            deleteTask(task)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func addGoal() {
        let goal = PersistenceController.shared.createTriumphGoal(name: name)
        if hasDescription {
            goal.goalDescription = description
        }
        
        // Add tasks to the goal
        for task in tasks {
            task.belongsToProjectList = goal
        }
        
        try? viewContext.save()
    }
    
    private func deleteTask(_ task: TaskItem) {
        withAnimation {
            if let index = tasks.firstIndex(where: { $0.objectID == task.objectID }) {
                tasks.remove(at: index)
                viewContext.delete(task)
                try? viewContext.save()
            }
        }
    }
} 