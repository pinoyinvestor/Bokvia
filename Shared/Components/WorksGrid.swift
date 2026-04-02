import SwiftUI

struct WorksGrid: View {
    let works: [Work]
    let onTap: (Work) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(works) { work in
                WorkCell(work: work)
                    .onTapGesture { onTap(work) }
            }
        }
    }
}

// Built by Christos Ferlachidis & Daniel Hedenberg

struct WorkCell: View {
    let work: Work
    @State private var isLiked: Bool
    @State private var isSaved: Bool
    @State private var likeCount: Int

    init(work: Work) {
        self.work = work
        _isLiked = State(initialValue: work.isLiked ?? false)
        _isSaved = State(initialValue: work.isSaved ?? false)
        _likeCount = State(initialValue: work.likeCount)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let url = work.mediaUrls.first, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                    }
                    .frame(width: geo.size.width, height: geo.size.width)
                    .clipped()
                }

                // Carousel indicator
                if work.mediaUrls.count > 1 {
                    HStack(spacing: 2) {
                        Image(systemName: "square.on.square")
                            .font(.caption2)
                        Text("\(work.mediaUrls.count)")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .accessibilityLabel("\(work.mediaUrls.count) photos")
                }

                // Overlay action buttons
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        // Like count badge
                        if likeCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: isLiked ? "heart.fill" : "heart.fill")
                                    .font(.caption2)
                                Text("\(likeCount)")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(6)
                        }

                        Spacer()

                        // Action buttons
                        VStack(spacing: 6) {
                            Button {
                                Task { await toggleLike() }
                            } label: {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.caption)
                                    .foregroundStyle(isLiked ? .red : .white)
                                    .frame(width: 28, height: 28)
                                    .background(.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(isLiked ? "Unlike" : "Like")

                            Button {
                                Task { await toggleSave() }
                            } label: {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .font(.caption)
                                    .foregroundStyle(isSaved ? .yellow : .white)
                                    .frame(width: 28, height: 28)
                                    .background(.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(isSaved ? "Unsave" : "Save")
                        }
                        .padding(6)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

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
}
