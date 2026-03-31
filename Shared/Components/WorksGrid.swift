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

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
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

                // Like count
                if work.likeCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                        Text("\(work.likeCount)")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
