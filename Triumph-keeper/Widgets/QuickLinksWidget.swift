import SwiftUI
import CoreData
import WebKit
import WidgetKit

struct WebPreview: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct QuickLinksWidget: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \QuickLinkItem.displayOrder, ascending: true)],
        animation: .default)
    private var links: FetchedResults<QuickLinkItem>
    
    @State private var isAddingLink = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Quick Links", systemImage: "link")
                    .font(.headline)
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                    Button(action: { isAddingLink = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.bottom, 4)
            
            if links.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "link.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.7))
                    Text("No links yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: { isAddingLink = true }) {
                        Text("Add Link")
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
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) {
                        ForEach(links, id: \.objectID) { link in
                            LinkRow(link: link)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                       radius: 10, x: 0, y: 4)
        )
        .sheet(isPresented: $isAddingLink) {
            AddLinkView(isPresented: $isAddingLink)
        }
        .alert("Delete All Links", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllLinks()
            }
        } message: {
            Text("Are you sure you want to delete all quick links?")
        }
    }
    
    private func deleteAllLinks() {
        withAnimation {
            viewContext.performAndWait {
                // Delete all links
                for link in links {
                    viewContext.delete(link)
                }
                do {
                    try viewContext.save()
                } catch {
                    print("Error deleting all links: \(error)")
                }
            }
        }
    }
}

struct LinkRow: View {
    let link: QuickLinkItem
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showWebView = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    private func getFaviconURL(from urlString: String) -> URL? {
        guard let url = URL(string: urlString),
              let host = url.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")
    }
    
    var body: some View {
        if let url = URL(string: link.urlString ?? "") {
            Button(action: {
                showWebView = true
            }) {
                HStack(spacing: 12) {
                    // Website favicon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        if let faviconURL = getFaviconURL(from: link.urlString ?? "") {
                            AsyncImage(url: faviconURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            } placeholder: {
                                Text(String(url.host?.prefix(1) ?? "").uppercased())
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Text(String(url.host?.prefix(1) ?? "").uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Website info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(link.title ?? "")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(url.host ?? "")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
            .contextMenu {
                Button(action: {
                    showEditSheet = true
                }) {
                    Label("Edit Link", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Link", systemImage: "trash")
                }
            }
            .sheet(isPresented: $showWebView) {
                NavigationView {
                    WebView(url: url)
                        .navigationTitle(link.title ?? "")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    showWebView = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditLinkView(link: link, isPresented: $showEditSheet)
            }
            .alert("Delete Link", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteLink()
                }
            } message: {
                Text("Are you sure you want to delete this link?")
            }
        } else {
            Text(link.title ?? "")
                .lineLimit(1)
        }
    }
    
    private func deleteLink() {
        withAnimation {
            viewContext.performAndWait {
                viewContext.delete(link)
                do {
                    try viewContext.save()
                } catch {
                    print("Error deleting link: \(error)")
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct AddLinkView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var urlString = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .textContentType(.name)
                    TextField("URL", text: $urlString)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                } footer: {
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Link")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addLink()
                    }
                    .disabled(title.isEmpty || urlString.isEmpty)
                    .font(.headline)
                }
            }
        }
    }
    
    private func addLink() {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            showError = true
            errorMessage = "Please enter a valid URL"
            return
        }
        
        PersistenceController.shared.createQuickLink(title: title, urlString: urlString)
        isPresented = false
    }
}

struct EditLinkView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let link: QuickLinkItem
    @Binding var isPresented: Bool
    
    @State private var title: String
    @State private var urlString: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(link: QuickLinkItem, isPresented: Binding<Bool>) {
        self.link = link
        self._isPresented = isPresented
        self._title = State(initialValue: link.title ?? "")
        self._urlString = State(initialValue: link.urlString ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .textContentType(.name)
                    TextField("URL", text: $urlString)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                } footer: {
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Link")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateLink()
                    }
                    .disabled(title.isEmpty || urlString.isEmpty)
                    .font(.headline)
                }
            }
        }
    }
    
    private func updateLink() {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            showError = true
            errorMessage = "Please enter a valid URL"
            return
        }
        
        // Delete the old link
        viewContext.delete(link)
        
        // Create a new link with the updated values
        PersistenceController.shared.createQuickLink(title: title, urlString: urlString)
        
        // Save the context
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            showError = true
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
    }
} 