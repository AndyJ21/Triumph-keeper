import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WidgetConfiguration.displayOrder, ascending: true)],
        animation: .default)
    private var widgets: FetchedResults<WidgetConfiguration>
    
    @State private var isAddingWidget = false
    
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
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome to")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Triumph Board")
                                    .font(.system(size: 34, weight: .bold))
                            }
                            Spacer()
                            
                            Button(action: { isAddingWidget = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        if widgets.isEmpty {
                            EmptyDashboardView(isAddingWidget: $isAddingWidget)
                                .frame(height: 300)
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 16)
                                ],
                                spacing: 16
                            ) {
                                ForEach(widgets) { widget in
                                    widgetView(for: widget)
                                        .frame(height: 300)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isAddingWidget) {
                AddWidgetView(isPresented: $isAddingWidget)
            }
        }
    }
    
    @ViewBuilder
    private func widgetView(for widget: WidgetConfiguration) -> some View {
        switch widget.type {
        case "quicklinks":
            QuickLinksWidget()
                .transition(.scale)
                .frame(height: 180)
        case "triumphgoals":
            TriumphGoalsWidget()
                .transition(.scale)
                .frame(height: 300)
        case "knowledgebytes":
            KnowledgeByteWidget()
                .transition(.scale)
                .frame(height: 300)
        default:
            Text("Unknown Widget Type: \(widget.type ?? "nil")")
                .foregroundColor(.red)
        }
    }
}

struct EmptyDashboardView: View {
    @Binding var isAddingWidget: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Your Dashboard is Empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add widgets to start tracking your triumphs")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { isAddingWidget = true }) {
                Text("Add Your First Widget")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
        .padding()
    }
}

struct AddWidgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    
    let widgetTypes = [
        (name: "Quick Links", type: "quicklinks", icon: "link", description: "Save and organize your important links"),
        (name: "Triumph Goals", type: "triumphgoals", icon: "checkmark.circle", description: "Track your goals and achievements"),
        (name: "Knowledge Bytes", type: "knowledgebytes", icon: "doc.text.magnifyingglass", description: "Store and access code snippets and technical notes")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(widgetTypes, id: \.type) { widgetType in
                    let existingWidgets = PersistenceController.shared.fetchWidgetConfigurations(ofType: widgetType.type)
                    let isWidgetTypeExists = !existingWidgets.isEmpty
                    
                    Button(action: {
                        if !isWidgetTypeExists {
                            addWidget(type: widgetType.type)
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                Image(systemName: widgetType.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(widgetType.name)
                                    .font(.headline)
                                Text(widgetType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if isWidgetTypeExists {
                                Text("Added")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(isWidgetTypeExists)
                }
            }
            .navigationTitle("Add Widget")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func addWidget(type: String) {
        PersistenceController.shared.createWidgetConfiguration(type: type)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
