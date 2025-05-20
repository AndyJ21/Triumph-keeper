import SwiftUI
import CoreData

struct KnowledgeByteWidget: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \KnowledgeByte.dateCreated, ascending: false)],
        animation: .default)
    private var knowledgeBytes: FetchedResults<KnowledgeByte>
    
    @State private var selectedByte: KnowledgeByte?
    @State private var showingDetail = false
    @State private var showingAddSheet = false
    @State private var showDeleteAlert = false
    @State private var byteToDelete: KnowledgeByte?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Label("Knowledge Bytes", systemImage: "doc.text.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 16) {
                    if !knowledgeBytes.isEmpty {
                        Button(action: { showDeleteAlert = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
                    }
                    Button(action: { 
                        createAndShowNewByte()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Content
            if knowledgeBytes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("No snippets found")
                        .font(.headline)
                    Text("Add your first knowledge byte")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(knowledgeBytes, id: \.id) { byte in
                            HStack {
                                Button(action: {
                                    selectedByte = byte
                                    showingDetail = true
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(byte.title ?? "Untitled")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if byte.isFavorite {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                        
                                        if let language = byte.languageOrType {
                                            Text(language)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                        
                                        Text(byte.content)
                                            .font(.body)
                                            .lineLimit(2)
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(radius: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    byteToDelete = byte
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.red.opacity(0.8))
                                        .padding(8)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
        .sheet(isPresented: $showingAddSheet) {
            if let byte = selectedByte {
                NavigationView {
                    KnowledgeByteDetailView(byte: byte, onSave: {
                        viewContext.refresh(byte, mergeChanges: true)
                    })
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let byte = selectedByte {
                NavigationView {
                    KnowledgeByteDetailView(byte: byte, onSave: {
                        viewContext.refresh(byte, mergeChanges: true)
                    })
                }
            }
        }
        .alert("Delete All Knowledge Bytes", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllBytes()
            }
        } message: {
            Text("Are you sure you want to delete all knowledge bytes? This action cannot be undone.")
        }
        .alert("Delete Knowledge Byte", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let byte = byteToDelete {
                    deleteByte(byte)
                }
            }
        } message: {
            Text("Are you sure you want to delete this knowledge byte? This action cannot be undone.")
        }
    }
    
    private func deleteByte(_ byte: KnowledgeByte) {
        // Delete the byte
        viewContext.delete(byte)
        
        // Save changes with a slight delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try self.viewContext.save()
                print("Successfully deleted knowledge byte")
            } catch {
                print("Error deleting knowledge byte: \(error)")
                self.viewContext.rollback()
            }
        }
    }
    
    private func createAndShowNewByte() {
        let newByte = KnowledgeByte(context: viewContext)
        newByte.id = UUID()
        newByte.dateCreated = Date()
        newByte.isFavorite = false
        newByte.displayOrder = 0
        newByte.content = ""
        newByte.title = ""
        
        do {
            try viewContext.save()
            print("Successfully created new byte with ID: \(newByte.id)")
            selectedByte = newByte
            showingAddSheet = true
            viewContext.refresh(newByte, mergeChanges: true)
        } catch {
            print("Error creating new byte: \(error)")
            viewContext.rollback()
        }
    }
    
    private func deleteAllBytes() {
        // Create a copy of the array to avoid modification during iteration
        let bytesToDelete = Array(knowledgeBytes)
        
        // Delete each byte
        for byte in bytesToDelete {
            viewContext.delete(byte)
        }
        
        // Save changes with a slight delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try self.viewContext.save()
                print("Successfully deleted all knowledge bytes")
            } catch {
                print("Error deleting knowledge bytes: \(error)")
                self.viewContext.rollback()
            }
        }
    }
}

struct KnowledgeByteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var byte: KnowledgeByte
    let onSave: () -> Void
    
    @State private var title: String
    @State private var content: String
    @State private var languageOrType: String
    @State private var tags: String
    @State private var isFavorite: Bool
    
    init(byte: KnowledgeByte, onSave: @escaping () -> Void) {
        self.byte = byte
        self.onSave = onSave
        _title = State(initialValue: byte.title ?? "")
        _content = State(initialValue: byte.content)
        _languageOrType = State(initialValue: byte.languageOrType ?? "")
        _tags = State(initialValue: byte.tags ?? "")
        _isFavorite = State(initialValue: byte.isFavorite)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Title", text: $title)
                TextField("Language/Type", text: $languageOrType)
                TextField("Tags (comma-separated)", text: $tags)
                Toggle("Favorite", isOn: $isFavorite)
            }
            
            Section(header: Text("Content")) {
                TextEditor(text: $content)
                    .frame(minHeight: 200)
            }
        }
        .navigationTitle("Knowledge Byte")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    if content.isEmpty {
                        viewContext.delete(byte)
                        do {
                            try viewContext.save()
                            print("Successfully deleted unsaved byte")
                        } catch {
                            print("Error deleting unsaved byte: \(error)")
                        }
                    }
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                    onSave()
                    dismiss()
                }
            }
        }
        .onAppear {
            // Ensure the byte is refreshed when the view appears
            viewContext.refresh(byte, mergeChanges: true)
        }
        .onChange(of: content) { newContent in
            byte.content = newContent
            do {
                try viewContext.save()
                print("Successfully updated content for byte: \(byte.id)")
            } catch {
                print("Error updating content: \(error)")
            }
        }
    }
    
    private func saveChanges() {
        guard !content.isEmpty else { return }
        
        byte.title = title.isEmpty ? nil : title
        byte.content = content
        byte.languageOrType = languageOrType.isEmpty ? nil : languageOrType
        byte.tags = tags.isEmpty ? nil : tags
        byte.isFavorite = isFavorite
        byte.lastAccessed = Date()
        
        do {
            try viewContext.save()
            print("Successfully saved knowledge byte with ID: \(byte.id)")
        } catch {
            print("Error saving knowledge byte: \(error)")
        }
    }
}

struct KnowledgeByteWidget_Previews: PreviewProvider {
    static var previews: some View {
        KnowledgeByteWidget()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 