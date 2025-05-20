import SwiftUI
import WidgetKit

@main
struct Triumph_keeperApp: App {
    let persistenceController = PersistenceController.shared
    @State private var widgetGroup = "group.com.yourdomain.Triumph-keeper"
    
    init() {
        // Register for URL scheme handling
        if let url = URL(string: "triumph-keeper://remove-widget") {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    setupWidgetRemovalObserver()
                }
                .onOpenURL { url in
                    if url.scheme == "triumph-keeper" && url.host == "remove-widget" {
                        handleWidgetRemoval()
                    }
                }
        }
    }
    
    private func setupWidgetRemovalObserver() {
        // Check for widget removal requests
        if let sharedDefaults = UserDefaults(suiteName: widgetGroup) {
            if sharedDefaults.bool(forKey: "removeQuickLinksWidget") {
                handleWidgetRemoval()
            }
        }
        
        // Set up a timer to periodically check for removal requests
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let sharedDefaults = UserDefaults(suiteName: widgetGroup) {
                if sharedDefaults.bool(forKey: "removeQuickLinksWidget") {
                    handleWidgetRemoval()
                }
            }
        }
    }
    
    private func handleWidgetRemoval() {
        // Reset the flag
        if let sharedDefaults = UserDefaults(suiteName: widgetGroup) {
            sharedDefaults.set(false, forKey: "removeQuickLinksWidget")
            sharedDefaults.synchronize()
        }
        
        // Get current widget configurations
        WidgetCenter.shared.getCurrentConfigurations { result in
            switch result {
            case .success(let configurations):
                // Find the QuickLinks widget configuration
                if let quickLinksConfig = configurations.first(where: { $0.kind.contains("QuickLinksWidget") }) {
                    // Remove the widget
                    WidgetCenter.shared.reloadTimelines(ofKind: quickLinksConfig.kind)
                }
            case .failure(let error):
                print("Error handling widget removal: \(error)")
            }
        }
    }
}
