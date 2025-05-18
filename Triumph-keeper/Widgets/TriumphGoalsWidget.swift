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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Triumph Goals", systemImage: "flag.fill")
                    .font(.headline)
                Spacer()
                Button(action: { isAddingGoal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
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
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(goals) { goal in
                            GoalRow(goal: goal, isSelected: selectedGoal == goal)
                                .onTapGesture {
                                    withAnimation {
                                        selectedGoal = goal
                                    }
                                }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                       radius: 10, x: 0, y: 4)
        )
        .sheet(isPresented: $isAddingGoal) {
            AddGoalView(isPresented: $isAddingGoal)
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailView(goal: goal)
        }
    }
}

struct GoalRow: View {
    let goal: TriumphGoal
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
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
    
    var tasks: [TaskItem] {
        (goal.tasks?.allObjects as? [TaskItem])?.sorted { ($0.displayOrder, $0.dateCreated ?? Date()) < ($1.displayOrder, $1.dateCreated ?? Date()) } ?? []
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(tasks) { task in
                        TaskRow(task: task) {
                            taskToDelete = task
                            showDeleteConfirmation = true
                        }
                    }
                } header: {
                    if !tasks.isEmpty {
                        Text("Tasks")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(goal.name ?? "")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingTask = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(goal: goal, isPresented: $isAddingTask)
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
            viewContext.delete(task)
            try? viewContext.save()
        }
    }
}

struct TaskRow: View {
    @ObservedObject var task: TaskItem
    @Environment(\.managedObjectContext) private var viewContext
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.text ?? "")
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                if let dueDate = task.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dueDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func toggleCompletion() {
        withAnimation {
            task.isCompleted.toggle()
            try? viewContext.save()
        }
    }
}

struct AddTaskView: View {
    let goal: TriumphGoal
    @Binding var isPresented: Bool
    @State private var text = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Task Description", text: $text)
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTask()
                        isPresented = false
                    }
                    .disabled(text.isEmpty)
                    .font(.headline)
                }
            }
        }
    }
    
    private func addTask() {
        PersistenceController.shared.createTask(
            text: text,
            dueDate: hasDueDate ? dueDate : nil,
            for: goal
        )
    }
}

struct AddGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    @State private var name = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Goal Name", text: $name)
                }
            }
            .navigationTitle("Add Goal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addGoal()
                        isPresented = false
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addGoal() {
        PersistenceController.shared.createTriumphGoal(name: name)
    }
} 