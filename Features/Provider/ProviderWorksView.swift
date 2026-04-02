import SwiftUI
import PhotosUI

struct ProviderWorksView: View {
    @Environment(AppState.self) private var appState
    @State private var works: [Work] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showUploadSheet = false
    @State private var providerId: String?
    @State private var selectedWork: Work?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }

                        uploadButton

                        if works.isEmpty {
                            emptyState
                        } else {
                            worksContent
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadWorks() }
        .refreshable { await loadWorks() }
        .sheet(isPresented: $showUploadSheet) {
            NavigationStack {
                UploadWorkForm(providerId: providerId ?? "") {
                    showUploadSheet = false
                    Task { await loadWorks() }
                }
            }
        }
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    // MARK: - Upload Button

    private var uploadButton: some View {
        Button {
            showUploadSheet = true
        } label: {
            Label(appState.isSv ? "Ladda upp arbete" : "Upload work", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(BokviaTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .accessibilityLabel(appState.isSv ? "Ladda upp nytt arbete" : "Upload new work")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(appState.isSv ? "Inget portfolio ännu" : "No portfolio yet")
                .font(.headline)
            Text(appState.isSv ? "Ladda upp bilder av ditt arbete!" : "Upload photos of your work!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Works Content

    private var worksContent: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(works.count) \(appState.isSv ? "arbeten" : "works")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            WorksGrid(works: works) { work in
                selectedWork = work
            }
            .navigationDestination(item: $selectedWork) { work in
                WorkDetailView(work: work)
            }

            // Stats below grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(works.prefix(6)) { work in
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            HStack(spacing: 2) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                Text("\(work.likeCount)")
                                    .font(.caption2)
                            }
                            HStack(spacing: 2) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                Text("\(work.commentCount)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Data Loading

    private func loadWorks() async {
        isLoading = true
        errorMessage = nil
        do {
            let me = try await APIClient.shared.get("/api/providers/me", as: ProviderMeResponse.self)
            providerId = me.id
            let result = try await APIClient.shared.getNoAuth("/api/works/provider/\(me.id)", as: WorksExploreResponse.self)
            works = result.items
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda portfolio." : "Failed to load portfolio."
        }
        isLoading = false
    }
}

// MARK: - Upload Work Form

struct UploadWorkForm: View {
    let providerId: String
    let onUploaded: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var caption = ""
    @State private var selectedServiceId: String?
    @State private var services: [Service] = []
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(appState.isSv ? "Bilder (max 6)" : "Images (max 6)") {
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 6,
                    matching: .images
                ) {
                    Label(
                        appState.isSv ? "Välj bilder (\(selectedImages.count)/6)" : "Select images (\(selectedImages.count)/6)",
                        systemImage: "photo.on.rectangle.angled"
                    )
                }
                .accessibilityLabel(appState.isSv ? "Välj bilder" : "Select images")
                .onChange(of: selectedPhotos) { _, items in
                    Task { await loadImages(items) }
                }

                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedImages.indices, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }

            // Built by Christos Ferlachidis & Daniel Hedenberg

            Section(appState.isSv ? "Tjänst" : "Service") {
                Picker(appState.isSv ? "Välj tjänst" : "Select service", selection: $selectedServiceId) {
                    Text(appState.isSv ? "Ingen" : "None").tag(nil as String?)
                    ForEach(services) { service in
                        Text(service.name(locale: appState.language)).tag(service.id as String?)
                    }
                }
                .accessibilityLabel(appState.isSv ? "Välj tjänst" : "Select service")
            }

            Section(appState.isSv ? "Bildtext" : "Caption") {
                TextField(appState.isSv ? "Beskriv ditt arbete..." : "Describe your work...", text: $caption)
                    .accessibilityLabel(appState.isSv ? "Bildtext" : "Caption")
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle(appState.isSv ? "Nytt arbete" : "New work")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(appState.isSv ? "Ladda upp" : "Upload") {
                    Task { await upload() }
                }
                .disabled(isUploading || selectedImages.isEmpty)
                .accessibilityLabel(appState.isSv ? "Ladda upp" : "Upload")
            }
        }
        .task { await loadServices() }
    }

    private func loadImages(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        selectedImages = images
    }

    private func loadServices() async {
        services = (try? await APIClient.shared.get("/api/providers/\(providerId)/services", as: [Service].self)) ?? []
    }

    private func upload() async {
        guard let firstImage = selectedImages.first,
              let imageData = firstImage.jpegData(compressionQuality: 0.8) else { return }

        isUploading = true
        errorMessage = nil

        var fields: [String: String] = [:]
        if !caption.isEmpty { fields["caption"] = caption }
        if let serviceId = selectedServiceId { fields["serviceId"] = serviceId }

        do {
            _ = try await APIClient.shared.uploadImage(
                "/api/works",
                imageData: imageData,
                filename: "work_\(UUID().uuidString).jpg",
                fields: fields,
                as: Work.self
            )
            HapticManager.success()
            onUploaded()
        } catch {
            errorMessage = appState.isSv ? "Uppladdningen misslyckades." : "Upload failed."
            HapticManager.error()
        }
        isUploading = false
    }
}
