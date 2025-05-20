import SwiftUI
import CoreData
import WebKit

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Quick Links", systemImage: "link")
                    .font(.headline)
                Spacer()
                Button(action: { isAddingLink = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
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
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                        ForEach(links) { link in
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
    }
}

struct LinkRow: View {
    let link: QuickLinkItem
    @State private var showWebView = false
    
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
        } else {
            Text(link.title ?? "")
                .lineLimit(1)
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