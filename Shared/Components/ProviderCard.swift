import SwiftUI

struct ProviderCard: View {
    let provider: DiscoverProvider
    let locale: String

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: provider.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(BokviaTheme.gray200)
                    .overlay(
                        Text(String(provider.displayName.prefix(1)))
                            .font(.title3.bold())
                            .foregroundStyle(BokviaTheme.gray500)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(provider.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if provider.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(BokviaTheme.accent)
                    }
                }

                // Built by Christos Ferlachidis & Daniel Hedenberg

                // Price — prominent
                if let price = provider.startingPrice {
                    Text(locale == "en" ? "From \(Int(price)) kr" : "Från \(Int(price)) kr")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BokviaTheme.accent)
                }

                if let city = provider.city {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(city)
                            .font(.caption)
                        if let dist = provider.distance {
                            Text("· \(String(format: "%.1f", dist)) km")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    if provider.reviewCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", provider.ratingAvg))
                                .font(.caption.weight(.medium))
                            Text("(\(provider.reviewCount))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Social proof — booking count
                    if let count = provider.bookingsCount, count > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.caption2)
                            Text(locale == "en" ? "\(count) bookings" : "\(count) bokningar")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                if let tags = provider.subcategoryTags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.nameSv) { tag in
                            Text(locale == "en" ? tag.nameEn : tag.nameSv)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BokviaTheme.accentLight)
                                .foregroundStyle(BokviaTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            // Boka button
            VStack {
                Spacer()
                Text(locale == "en" ? "Book" : "Boka")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BokviaTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
