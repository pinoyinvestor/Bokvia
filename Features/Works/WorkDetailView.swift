import SwiftUI

struct WorkDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let work: Work

    @State private var isLiked: Bool
    @State private var isSaved: Bool
    @State private var likeCount: Int
    @State private var comments: [WorkComment] = []
    @State private var isLoadingComments = true
    @State private var commentText = ""
    @State private var isSendingComment = false
    @State private var currentImageIndex = 0
    @State private var errorMessage: String?

    init(work: Work) {
        self.work = work
        _isLiked = State(initialValue: work.isLiked ?? false)
        _isSaved = State(initialValue: work.isSaved ?? false)
        _likeCount = State(initialValue: work.likeCount)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                imageCarousel

                actionBar

                // Built by Christos Ferlachidis & Daniel Hedenberg

                contentSection

                Divider().padding(.vertical, 8)

                commentsSection

                commentInput
            }
        }
        .navigationTitle(appState.isSv ? "Arbete" : "Work")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadComments() }
    }

    // MARK: - Image Carousel

    private var imageCarousel: some View {
        TabView(selection: $currentImageIndex) {
            ForEach(Array(work.mediaUrls.enumerated()), id: \.offset) { index, urlStr in
                if let url = URL(string: urlStr) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(ProgressView())
                    }
                    .tag(index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: work.mediaUrls.count > 1 ? .always : .never))
        .frame(height: UIScreen.main.bounds.width)
        .background(Color(.systemGray6))
        .accessibilityLabel(appState.isSv
            ? "Bild \(currentImageIndex + 1) av \(work.mediaUrls.count)"
            : "Image \(currentImageIndex + 1) of \(work.mediaUrls.count)")
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 20) {
            Button {
                Task { await toggleLike() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : .primary)
                    Text("\(likeCount)")
                        .font(.subheadline)
                }
            }
            .accessibilityLabel(isLiked
                ? (appState.isSv ? "Ta bort gilla, \(likeCount) gillar" : "Unlike, \(likeCount) likes")
                : (appState.isSv ? "Gilla, \(likeCount) gillar" : "Like, \(likeCount) likes"))

            Button {
                Task { await toggleSave() }
            } label: {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isSaved ? BokviaTheme.accent : .primary)
            }
            .accessibilityLabel(isSaved
                ? (appState.isSv ? "Ta bort sparad" : "Unsave")
                : (appState.isSv ? "Spara" : "Save"))

            HStack(spacing: 4) {
                Image(systemName: "bubble.right")
                Text("\(comments.count)")
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            .accessibilityLabel(appState.isSv ? "\(comments.count) kommentarer" : "\(comments.count) comments")

            Spacer()
        }
        .font(.title3)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Provider info
            if let provider = work.provider {
                NavigationLink {
                    ProviderProfileView(slug: provider.slug ?? provider.id)
                } label: {
                    HStack(spacing: 10) {
                        AsyncImage(url: URL(string: provider.avatarUrl ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(BokviaTheme.gray200)
                                .overlay(
                                    Text(String(provider.displayName.prefix(1)))
                                        .font(.caption.bold())
                                        .foregroundStyle(BokviaTheme.gray500)
                                )
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())

                        Text(provider.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .accessibilityLabel(appState.isSv ? "Visa profil för \(provider.displayName)" : "View profile for \(provider.displayName)")
            }

            // Caption
            if let caption = work.caption, !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
                    .padding(.top, 2)
            }

            // Service tag
            if let service = work.service {
                HStack(spacing: 6) {
                    Image(systemName: "scissors")
                        .font(.caption2)
                    Text(appState.isSv ? service.nameSv : (service.nameEn ?? service.nameSv))
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(BokviaTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(BokviaTheme.accentLight)
                .clipShape(Capsule())
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appState.isSv ? "Kommentarer" : "Comments")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal)

            if isLoadingComments {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if comments.isEmpty {
                Text(appState.isSv ? "Inga kommentarer ??n" : "No comments yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(comments) { comment in
                        commentRow(comment)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func commentRow(_ comment: WorkComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: URL(string: comment.user.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(
                        Text("\(comment.user.firstName.prefix(1))")
                            .font(.caption2.bold())
                            .foregroundStyle(BokviaTheme.gray500)
                    )
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(comment.user.firstName) \(comment.user.lastName)")
                        .font(.caption.weight(.semibold))
                    Text(comment.createdAt.prefix(10))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(comment.text)
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var commentInput: some View {
        HStack(spacing: 10) {
            TextField(
                appState.isSv ? "Skriv en kommentar..." : "Write a comment...",
                text: $commentText
            )
            .textFieldStyle(.roundedBorder)
            .font(.subheadline)

            Button {
                Task { await sendComment() }
            } label: {
                if isSendingComment {
                    ProgressView()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(commentText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : BokviaTheme.accent)
                        .frame(width: 32, height: 32)
                }
            }
            .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || isSendingComment)
            .accessibilityLabel(appState.isSv ? "Skicka kommentar" : "Send comment")
        }
        .padding()
    }

    // MARK: - Actions

    private func toggleLike() async {
        let wasLiked = isLiked
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        HapticManager.light()

        do {
            if wasLiked {
                try await APIClient.shared.delete("/api/works/\(work.id)/like")
            } else {
                struct Empty: Encodable {}
                _ = try await APIClient.shared.post("/api/works/\(work.id)/like", body: Empty(), as: EmptyResponse.self)
            }
        } catch {
            isLiked = wasLiked
            likeCount += wasLiked ? 1 : -1
        }
    }

    private func toggleSave() async {
        let wasSaved = isSaved
        isSaved.toggle()
        HapticManager.light()

        do {
            if wasSaved {
                try await APIClient.shared.delete("/api/works/\(work.id)/save")
            } else {
                struct Empty: Encodable {}
                _ = try await APIClient.shared.post("/api/works/\(work.id)/save", body: Empty(), as: EmptyResponse.self)
            }
        } catch {
            isSaved = wasSaved
        }
    }

    private func loadComments() async {
        isLoadingComments = true
        do {
            let result = try await APIClient.shared.getOptionalAuth("/api/works/\(work.id)/comments", as: WorkCommentsResponse.self)
            comments = result.items
        } catch {
            // Silently fail - empty comments list shown
        }
        isLoadingComments = false
    }

    private func sendComment() async {
        let text = commentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isSendingComment = true
        errorMessage = nil

        struct CommentBody: Encodable { let text: String }
        do {
            let comment = try await APIClient.shared.post(
                "/api/works/\(work.id)/comments",
                body: CommentBody(text: text),
                as: WorkComment.self
            )
            comments.append(comment)
            commentText = ""
            HapticManager.success()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte skicka kommentar." : "Failed to send comment."
            HapticManager.error()
        }
        isSendingComment = false
    }
}

struct WorkCommentsResponse: Decodable {
    let items: [WorkComment]
    let total: Int?
}
