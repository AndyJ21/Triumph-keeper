import SwiftUI
import CoreData

struct QuickLinksWidget: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \QuickLinkItem.displayOrder, ascending: true)],
        animation: .default)
    private var links: FetchedResults<QuickLinkItem>
    
    @State private var isAddingLink = false
    @State private var showDeleteConfirmation = false
    @State private var linkToDelete: QuickLinkItem?
    
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
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(links) { link in
                            LinkRow(link: link) {
                                linkToDelete = link
                                showDeleteConfirmation = true
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
        .sheet(isPresented: $isAddingLink) {
            AddLinkView(isPresented: $isAddingLink)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Link"),
                message: Text("Are you sure you want to delete this link?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let link = linkToDelete {
                        deleteLink(link)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func deleteLink(_ link: QuickLinkItem) {
        withAnimation {
            viewContext.delete(link)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting link: \(error)")
            }
        }
    }
}

struct LinkRow: View {
    let link: QuickLinkItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            if let url = URL(string: link.urlString ?? "") {
                Link(destination: url) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(link.title ?? "")
                                .font(.system(.subheadline, design: .rounded))
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
                    .contentShape(Rectangle())
                }
            } else {
                Text(link.title ?? "")
                    .lineLimit(1)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
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